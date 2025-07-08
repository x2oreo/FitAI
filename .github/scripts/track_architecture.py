import os
import base64
import sys
from firebase_client import FirebaseClient

def main():
    try:
        # Initialize Firebase client with project name
        project_name = "test"  # Hardcoded project name
        firebase_client = FirebaseClient(project_name=project_name)
        
        # Get required environment variables
        repository = os.environ['REPOSITORY']
        pr_number = int(os.environ['PR_NUMBER'])
        diff_b64 = os.environ['DIFF_B64']
    
        print(f"Tracking architecture for project: {project_name}, repository: {repository}", file=sys.stderr)
        
        # Decode the diff
        diff = base64.b64decode(diff_b64).decode('utf-8')
        
        # Get additional metadata
        metadata = {
            'head_sha': os.environ.get('HEAD_SHA'),
            'base_sha': os.environ.get('BASE_SHA'),
            'pr_title': os.environ.get('PR_TITLE'),
            'pr_author': os.environ.get('PR_AUTHOR')
        }
        
        # Add the architecture change to Firebase
        # change_id = firebase_client.add_architecture_change(
        #     repository=repository,
        #     pr_number=pr_number,
        #     diff=diff,
        #     metadata=metadata
        # )
        
        # print(f"Architecture change added with ID: {change_id}", file=sys.stderr)
        
        # Check if we should regenerate the summary
        should_summarize = firebase_client.should_summarize(repository)
        
        # Increment changes count
        current_summary = firebase_client.get_architecture_summary(repository)
        if current_summary:
            changes_count = current_summary.get('changes_count', 0) + 1
            firebase_client.update_architecture_summary(
                repository=repository,
                summary=current_summary.get('summary', ''),
                changes_count=changes_count
            )
            print(f"Architecture summary updated with changes_count: {changes_count}", file=sys.stderr)
        else:
            print("No existing summary found, creating new one", file=sys.stderr)
            firebase_client.update_architecture_summary(
                repository=repository,
                summary="Initial architecture summary",
                changes_count=1
            )
        
        # Write outputs to GitHub Actions output file
        if 'GITHUB_OUTPUT' in os.environ:
            with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
                fh.write(f"should_summarize={str(should_summarize).lower()}\n")
                # fh.write(f"change_id={change_id}\n")
        else:
            # Fallback for local testing
            print(f"should_summarize={str(should_summarize).lower()}", file=sys.stderr)
            # print(f"change_id={change_id}", file=sys.stderr)
        
    except Exception as e:
        print(f"Error tracking architecture: {e}", file=sys.stderr)
        
        # Write error output to GitHub Actions output file
        if 'GITHUB_OUTPUT' in os.environ:
            with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
                fh.write("should_summarize=false\n")
        else:
            # Fallback for local testing
            print("should_summarize=false", file=sys.stderr)
        exit(1)

if __name__ == "__main__":
    main()