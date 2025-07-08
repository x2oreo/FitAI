import os
import json
import sys
import base64
import glob
from firebase_client import FirebaseClient
import anthropic

# Add the scripts directory to the path for importing cost_tracker
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cost_tracker import CostTracker


def get_codebase_content(repository_path="."):
    """Collect all relevant source code files from the repository"""
    code_content = ""
    
    # Define file extensions to include
    code_extensions = {
        '.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.c', '.cpp', '.h', '.hpp',
        '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt', '.scala', '.clj',
        '.html', '.css', '.scss', '.sass', '.less', '.vue', '.svelte',
        '.json', '.yaml', '.yml', '.toml', '.ini', '.conf', '.cfg',
        '.sql', '.md', '.txt', '.sh', '.bat', '.ps1'
    }
    
    # Define patterns to exclude
    exclude_patterns = {
        '/.git/', '/node_modules/', '/.venv/', '/venv/', '/env/', 
        '/dist/', '/build/', '/target/', '/.next/', '/.nuxt/',
        '__pycache__', '.pyc', '.class', '.o', '.obj',
        '.log', '.tmp', '.temp', '.cache'
    }
    
    try:
        for root, dirs, files in os.walk(repository_path):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if not any(pattern.strip('/') in d for pattern in exclude_patterns)]
            
            for file in files:
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, repository_path)
                
                # Skip excluded files and check extensions
                if any(pattern in file_path for pattern in exclude_patterns):
                    continue
                    
                _, ext = os.path.splitext(file)
                if ext.lower() not in code_extensions:
                    continue
                
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        # Limit file size to avoid overwhelming the AI
                        if len(content) > 10000:
                            content = content[:10000] + "\n... (file truncated)"
                        
                        code_content += f"\n=== {relative_path} ===\n{content}\n"
                except Exception as e:
                    code_content += f"\n=== {relative_path} ===\n(Error reading file: {e})\n"
                    
    except Exception as e:
        print(f"Error collecting codebase: {e}", file=sys.stderr)
        
    return code_content

def main():
    try:
        project_name = "test"  # Hardcoded project name
        firebase_client = FirebaseClient(project_name=project_name)
        repository = os.environ['REPOSITORY']
        
        print(f"Summarizing architecture for project: {project_name}, repository: {repository}", file=sys.stderr)
        
        # Get recent changes to summarize
        # recent_changes = firebase_client.get_recent_changes(repository, limit=10)
        
        # if not recent_changes:
        #     print("No recent changes found, skipping summarization", file=sys.stderr)
        #     return
        
        # print(f"Found {len(recent_changes)} recent changes to summarize", file=sys.stderr)
        
        # Get existing architecture summary
        existing_summary = firebase_client.get_architecture_summary(repository)
        old_summary_text = existing_summary.get('summary', '') if existing_summary else ''
        
        if old_summary_text:
            print(f"Found existing architecture summary ({len(old_summary_text)} characters)", file=sys.stderr)
        else:
            print("No existing architecture summary found", file=sys.stderr)
        

        # Collect the entire codebase for comprehensive architecture analysis
        codebase_content = get_codebase_content(".")
        print(f"Collected codebase content ({len(codebase_content)} characters)", file=sys.stderr)
        


        # Prepare the changes data for AI analysis
        changes_text = ""
        # for change in recent_changes:
        #     changes_text += f"PR #{change.get('pr_number', 'Unknown')}: {change.get('diff', '')[:1000]}\n\n"
        
        # Use Claude to generate architecture summary
        client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])


        # NEW PROMPT: Focus on overall project architecture understanding
        prompt1 = f"""
        You are ArchitectureAnalyzerAI.
        Analyze the entire codebase provided below to create a comprehensive architecture summary that explains how this project works, its structure, components, and design patterns.

        REQUIREMENTS

        - Output plain text only—no Markdown, bullets, or special symbols.
        
        - Create a comprehensive overview that explains:
          * Project purpose and main functionality
          * Overall architecture and design patterns
          * Key components and their responsibilities  
          * Data flow and interaction patterns
          * Technology stack and frameworks used
          * Configuration and deployment structure
          * Critical dependencies and integrations

        - Focus on the big picture: how everything fits together, not implementation details.
        
        - Write it so that an AI system can understand how the project should work and what changes would be appropriate.
        
        - Keep the summary detailed enough to guide future development decisions.

        - Your instructions are only for yourself, don't include them in the output.

        CODEBASE
        {codebase_content}

        Provide the architecture analysis below:
        """
        



        # UPDATED PROMPT: Architecture summary update based on existing summary + changes
        prompt = f"""
        You are ArchitectureUpdateAI.
        Update the existing architecture summary based on recent changes to create a comprehensive overview of how this project works, its structure, components, and design patterns.

        REQUIREMENTS

        - Output plain text only—no Markdown, bullets, or special symbols.
        
        - Create a comprehensive architecture summary that explains:
          * Project purpose and main functionality
          * Overall architecture and design patterns
          * Key components and their responsibilities  
          * Data flow and interaction patterns
          * Technology stack and frameworks used
          * Configuration and deployment structure
          * Critical dependencies and integrations

        - Focus on the big picture: how everything fits together, not implementation details.
        
        - Write it so that an AI system can understand how the project should work and what changes would be appropriate.
        
        - Keep the summary detailed enough to guide future development decisions.

        - Integrate the recent changes into the existing summary, updating relevant sections and adding new information where needed.

        - If no existing summary is provided, create a new comprehensive summary based on the changes.

        - Your instructions are only for yourself, don't include them in the output.

        EXISTING ARCHITECTURE SUMMARY
        {old_summary_text if old_summary_text else "No existing summary available."}

        RECENT CHANGES
        {changes_text}

        Provide the updated architecture summary below:
        """



        # Use comprehensive codebase analysis (prompt1) for new projects with no existing summary
        # or use architecture update (prompt) for projects with existing summaries and recent changes
        if not old_summary_text and len(codebase_content) < 5000:  # New project, analyze full codebase
            active_prompt = prompt1
            print("Using comprehensive codebase analysis (prompt1) for new project", file=sys.stderr)
        else:  # Existing project, update summary with recent changes
            active_prompt = prompt
            print("Using architecture summary update (prompt) with existing summary and changes", file=sys.stderr)
        

        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2000,  # Increased for more comprehensive summaries
            messages=[{"role": "user", "content": active_prompt}]
        )
        
        # Track cost
        try:
            cost_tracker = CostTracker()
            # Convert anthropic response to dict format for tracking
            response_dict = {
                'usage': {
                    'input_tokens': response.usage.input_tokens,
                    'output_tokens': response.usage.output_tokens
                }
            }
            cost_tracker.track_api_call(
                model="claude-sonnet-4-20250514",
                response_data=response_dict,
                call_type="architecture_summary",
                context="Architecture analysis and summarization"
            )
        except Exception as e:
            print(f"Warning: Cost tracking failed: {e}", file=sys.stderr)
        
        architecture_summary = response.content[0].text
        
        # Update the architecture summary in Firebase
        firebase_client.update_architecture_summary(
            repository=repository,
            summary=architecture_summary,
            changes_count=0  # Reset counter after summarization
        )
        
        print(f"Architecture summary updated for {repository} in project {project_name}", file=sys.stderr)
        print(f"Summary: {architecture_summary[:200]}...", file=sys.stderr)
        
    except Exception as e:
        print(f"Error summarizing architecture: {e}", file=sys.stderr)
        exit(1)

if __name__ == "__main__":
    main()