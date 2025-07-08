import json
import os
import sys
import subprocess
import base64
import re
from typing import List, Dict, Any


def clean_json_response(response_text: str) -> str:
    """Clean and extract JSON from AI response."""
    # Strip markdown code block formatting if present
    cleaned_text = response_text.replace('```json', '').replace('```', '').strip()
    
    # Look for JSON array pattern
    json_match = re.search(r'\[.*\]', cleaned_text, re.DOTALL)
    if json_match:
        return json_match.group(0)
    else:
        return cleaned_text


def parse_review_comments(review_text: str) -> List[Dict[str, Any]]:
    """Parse review text and extract comments."""
    json_text = clean_json_response(review_text)
    
    try:
        comments = json.loads(json_text)
        if not isinstance(comments, list):
            print(f"Response is not a JSON array. Type: {type(comments)}", file=sys.stderr)
            return []
        
        return comments
    except json.JSONDecodeError as e:
        print(f"Invalid JSON response: {e}", file=sys.stderr)
        
        # Try to fix common JSON issues
        try:
            fixed_json = json_text.replace("'", '"')  # Replace single quotes
            fixed_json = re.sub(r'(\w+):', r'"\1":', fixed_json)  # Add quotes to keys
            comments = json.loads(fixed_json)
            print("Successfully fixed JSON!", file=sys.stderr)
            return comments if isinstance(comments, list) else []
        except:
            print("Could not fix JSON", file=sys.stderr)
            return []


def post_line_comment(github_token: str, github_repo: str, pr_number: str, 
                     head_sha: str, path: str, line: int, comment: str) -> bool:
    """Post a single line comment to GitHub PR."""
    line_comment = {
        "body": comment,
        "path": path,
        "line": line,
        "side": "RIGHT",
        "commit_id": head_sha
    }
    
    with open('/tmp/line_comment.json', 'w') as f:
        json.dump(line_comment, f)
    
    result = subprocess.run([
        'curl', '-s', '-X', 'POST',
        '-H', f'Authorization: Bearer {github_token}',
        '-H', 'Content-Type: application/json',
        '-H', 'Accept: application/vnd.github+json',
        '--data', '@/tmp/line_comment.json',
        f'https://api.github.com/repos/{github_repo}/pulls/{pr_number}/comments'
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        try:
            response_data = json.loads(result.stdout)
            if 'message' in response_data:
                print(f"GitHub API Error for {path}:{line}: {response_data['message']}", file=sys.stderr)
                return False
            else:
                return True
        except json.JSONDecodeError:
            return True
    else:
        print(f"Failed to post comment for {path}:{line}: {result.stderr}", file=sys.stderr)
        return False


def post_summary_comment(github_token: str, github_repo: str, pr_number: str, 
                        comment_count: int, model_comment: str) -> bool:
    """Post a summary comment to GitHub PR."""
    if comment_count == 0:
        summary_text = f"✅ Code review completed - no issues found! {model_comment}"
    else:
        summary_text = f"📝 Code review completed with {comment_count} suggestions. {model_comment}"
    
    summary_comment = {"body": summary_text}
    with open('/tmp/summary_comment.json', 'w') as f:
        json.dump(summary_comment, f)
    
    result = subprocess.run([
        'curl', '-s', '-X', 'POST',
        '-H', f'Authorization: Bearer {github_token}',
        '-H', 'Content-Type: application/json',
        '--data', '@/tmp/summary_comment.json',
        f'https://api.github.com/repos/{github_repo}/issues/{pr_number}/comments'
    ], capture_output=True, text=True)
    
    return result.returncode == 0


def process_and_post_comments():
    """Main function to process AI review and post comments."""
    # Get environment variables
    review_b64 = os.environ.get('REVIEW_TEXT', '')
    model_comment = os.environ.get('MODEL_COMMENT', '')
    github_token = os.environ.get('GITHUB_TOKEN', '')
    github_repo = os.environ.get('GITHUB_REPOSITORY', '')
    pr_number = os.environ.get('PR_NUMBER', '')
    head_sha = os.environ.get('HEAD_SHA', '')
    
    if not all([review_b64, github_token, github_repo, pr_number, head_sha]):
        print("Missing required environment variables", file=sys.stderr)
        sys.exit(1)
    
    print(f"Processing review for PR #{pr_number}")
    
    # Decode the review text
    try:
        review_text = base64.b64decode(review_b64).decode('utf-8')
    except Exception as e:
        print(f"Failed to decode review text: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Parse comments
    comments = parse_review_comments(review_text)
    print(f"Found {len(comments)} review comments to post")
    
    if len(comments) == 0:
        print("No issues found in the code review - this is good!")
    
    # Post individual line comments
    comment_count = 0
    for comment_obj in comments:
        if not isinstance(comment_obj, dict):
            continue
        
        path = comment_obj.get('path')
        line = comment_obj.get('line')
        comment = comment_obj.get('comment')
        
        # Skip if any field is missing or invalid
        if not all([path, line, comment]) or not isinstance(line, int):
            print(f"Skipping invalid comment: {comment_obj}", file=sys.stderr)
            continue
        
        if post_line_comment(github_token, github_repo, pr_number, head_sha, path, line, comment):
            comment_count += 1
    
    print(f"Successfully posted {comment_count} line comments")
    
    # Post summary comment
    if post_summary_comment(github_token, github_repo, pr_number, comment_count, model_comment):
        print("Summary comment posted successfully")
    else:
        print("Failed to post summary comment", file=sys.stderr)


if __name__ == "__main__":
    process_and_post_comments()