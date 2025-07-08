import os
import json
import base64
import time
import sys
from datetime import datetime
from firebase_client import FirebaseClient

def retry_with_backoff(func, max_retries=3, base_delay=1):
    """Retry function with exponential backoff"""
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise e
            
            # Check for specific errors that shouldn't be retried
            error_str = str(e).lower()
            if any(term in error_str for term in ['invalid_grant', 'account not found', 'authentication']):
                raise e
            
            delay = base_delay * (2 ** attempt)
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay} seconds...", file=sys.stderr)
            time.sleep(delay)

def create_empty_context():
    """Create empty context for fallback"""
    project_name = "test"  # Hardcoded project name
    empty_context = {
        'architecture_summary': None,
        'recent_changes': [],
        'repository': os.environ.get('REPOSITORY', 'unknown'),
        'project_name': project_name,
        'status': 'fallback'
    }
    context_json = json.dumps(empty_context)
    return base64.b64encode(context_json.encode('utf-8')).decode('utf-8')

def read_local_architecture_summary():
    """Read the local architecture summary file"""
    try:
        # Look for architecture_summary.txt in the project root
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
        summary_path = os.path.join(project_root, 'architecture_summary.txt')
        
        if os.path.exists(summary_path):
            with open(summary_path, 'r', encoding='utf-8') as f:
                return f.read().strip()
        else:
            print(f"No local architecture summary found at {summary_path}", file=sys.stderr)
            return None
    except Exception as e:
        print(f"Error reading local architecture summary: {e}", file=sys.stderr)
        return None

def main():
    repository = os.environ.get('REPOSITORY')
    project_name = "test"  # Hardcoded project name
    
    if not repository:
        print("Error: REPOSITORY environment variable not set", file=sys.stderr)
        print(f"context_b64={create_empty_context()}", file=sys.stderr)
        return
    
    try:
        def fetch_firebase_data():
            firebase_client = FirebaseClient(project_name=project_name)
            
            # Get current architecture summary
            architecture_summary = firebase_client.get_architecture_summary(repository)
            
            # If no architecture summary found, create one from local file
            if not architecture_summary:
                print(f"No architecture summary found for {repository} in project {project_name}", file=sys.stderr)
                local_summary = read_local_architecture_summary()
                if local_summary:
                    print(f"Creating architecture summary for {repository} from local file", file=sys.stderr)
                    try:
                        firebase_client.update_architecture_summary(repository, local_summary, changes_count=0)
                        architecture_summary = {
                            'repository': repository,
                            'summary': local_summary,
                            'last_updated': datetime.utcnow().isoformat(),
                            'changes_count': 0
                        }
                        print(f"Successfully created architecture summary for {repository}", file=sys.stderr)
                    except Exception as e:
                        print(f"Error creating architecture summary: {e}", file=sys.stderr)
                        architecture_summary = None
                else:
                    print(f"No local architecture summary available to create Firebase entry", file=sys.stderr)
            
            # Get recent changes for additional context
            # recent_changes = firebase_client.get_recent_changes(repository, limit=5)
            
            return {
                'architecture_summary': architecture_summary,
                # 'recent_changes': recent_changes,
                'repository': repository,
                'project_name': project_name,
                'status': 'success'
            }
        
        # Try to fetch data with retries
        context_data = retry_with_backoff(fetch_firebase_data)
        
        # Encode context as base64
        context_json = json.dumps(context_data, default=str)
        context_b64 = base64.b64encode(context_json.encode('utf-8')).decode('utf-8')
        
        # Write output to GitHub Actions output file
        if 'GITHUB_OUTPUT' in os.environ:
            with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
                fh.write(f"context_b64={context_b64}\n")
        else:
            # Fallback for local testing
            print(f"context_b64={context_b64}", file=sys.stderr)
        
    except Exception as e:
        error_msg = str(e)
        print(f"Error fetching Firebase context: {error_msg}", file=sys.stderr)
        
        # Provide empty context on error but don't exit with error code
        # This allows the workflow to continue even if Firebase is unavailable
        empty_context_b64 = create_empty_context()
        
        # Write output to GitHub Actions output file
        if 'GITHUB_OUTPUT' in os.environ:
            with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
                fh.write(f"context_b64={empty_context_b64}\n")
        else:
            # Fallback for local testing
            print(f"context_b64={empty_context_b64}", file=sys.stderr)
        
        # Only exit with error code for critical failures
        if 'REPOSITORY' not in os.environ:
            sys.exit(1)

if __name__ == "__main__":
    main()
