import json
import os
import sys
import subprocess
from typing import List, Dict, Any
import base64


def read_architecture_context() -> str:
    """Read the architecture summary file for context."""
    file_path = "architecture_summary.txt"  # Use relative path

    if not os.environ.get('ARCHITECTURE_CONTEXT_B64'):
        if not os.path.exists(file_path):
            return "No existing architecture summary available."

        try:
            with open(file_path, 'r') as f:
                content = f.read()
                # Limit context to avoid token limits
                words = content.split()
                if len(words) > 1500:  # Limit to ~1500 words
                    content = ' '.join(words[:1500]) + \
                        "\n... (truncated for brevity)"
                return content
        except Exception as e:
            print(f'Error reading architecture summary: {e}', file=sys.stderr)
            return "Error reading architecture summary."
    else:
        try:
            context_json = base64.b64decode(
                os.environ['ARCHITECTURE_CONTEXT_B64']).decode('utf-8')
            architecture_context = json.loads(context_json)
            architecture_summary = architecture_context.get(
                'architecture_summary', {}).get('summary', '')
            recent_changes_context = ""
            recent_changes = architecture_context.get('recent_changes', [])[
                :3]  # Limit to 3 most recent
            for change in recent_changes:
                recent_changes_context += f"Recent PR #{change.get('pr_number', 'Unknown')}: {change.get('metadata', {}).get('pr_title', 'No title')}\n"
            return f"{architecture_summary}\n\n{recent_changes_context}"
        except Exception as e:
            print(
                f"Warning: Could not decode architecture context: {e}", file=sys.stderr)
            return "Error decoding architecture context."


def create_claude_payload(model: str, prompt: str) -> Dict[str, Any]:
    """Create payload for Claude API."""
    return {
        "model": model,
        "max_tokens": 10000,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }


def create_openai_payload(model: str, prompt: str) -> Dict[str, Any]:
    """Create payload for OpenAI API."""
    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }

    # Use max_completion_tokens for o3-mini, max_tokens for other models
    if model == "o3-mini":
        payload["max_completion_tokens"] = 10000
    else:
        payload["max_tokens"] = 10000

    return payload


def call_claude_api(api_key: str, payload: Dict[str, Any]) -> str:
    """Call Claude API and return the response content."""
    # Log minimal payload details
    payload_size = len(json.dumps(payload))
    prompt_length = len(payload.get('messages', [{}])[0].get('content', ''))

    print(f"Claude API call - Model: {payload.get('model', 'unknown')}", file=sys.stderr)
    
    # Log warning if payload is very large
    if payload_size > 100000:  # 100k bytes
        print(f"WARNING: Large payload detected ({payload_size:,} bytes)", file=sys.stderr)

    if prompt_length > 5000:  # 5k characters
        print(f"WARNING: Very long prompt detected ({prompt_length:,} characters)", file=sys.stderr)

    with open('/tmp/claude_payload.json', 'w') as f:
        json.dump(payload, f)

    result = subprocess.run([
        'curl', '-s', 'https://api.anthropic.com/v1/messages',
        '-H', f'x-api-key: {api_key}',
        '-H', 'anthropic-version: 2023-06-01',
        '-H', 'Content-Type: application/json',
        '-d', '@/tmp/claude_payload.json'
    ], capture_output=True, text=True)

    if result.returncode != 0:
        print(f'Claude API call failed: {result.stderr}', file=sys.stderr)
        return '[]'

    print(f"Claude API response status: success", file=sys.stderr)

    try:
        data = json.loads(result.stdout)
        if 'error' in data:
            error_info = data['error']
            error_type = error_info.get('type', 'unknown')
            error_message = error_info.get('message', 'unknown error')
            print(
                f'Claude API Error - Type: {error_type}, Message: {error_message}', file=sys.stderr)

            # Check for common payload size related errors
            if 'too_large' in error_message.lower() or 'limit' in error_message.lower():
                print(f'ERROR: Payload may be too large for Claude API',
                      file=sys.stderr)

            return '[]'

        if 'content' in data and isinstance(data['content'], list) and len(data['content']) > 0:
            return data['content'][0].get('text', '[]')
        else:
            return data.get('text', '[]')
    except Exception as e:
        print(f'Error parsing Claude response: {e}', file=sys.stderr)
        return '[]'


def call_openai_api(api_key: str, payload: Dict[str, Any]) -> str:
    """Call OpenAI API and return the response content."""
    # Log minimal payload details
    print(f"OpenAI API call - Model: {payload.get('model', 'unknown')}", file=sys.stderr)
    
    with open('/tmp/openai_payload.json', 'w') as f:
        json.dump(payload, f)

    result = subprocess.run([
        'curl', '-s', 'https://api.openai.com/v1/chat/completions',
        '-H', f'Authorization: Bearer {api_key}',
        '-H', 'Content-Type: application/json',
        '-d', '@/tmp/openai_payload.json'
    ], capture_output=True, text=True)

    if result.returncode != 0:
        print(f'OpenAI API call failed: {result.stderr}', file=sys.stderr)
        return '[]'

    try:
        data = json.loads(result.stdout)
        if 'error' in data:
            print(f'OpenAI API Error: {data["error"]}', file=sys.stderr)
            return '[]'

        return data.get('choices', [{}])[0].get('message', {}).get('content', '[]')
    except Exception as e:
        print(f'Error parsing OpenAI response: {e}', file=sys.stderr)
        return '[]'


def create_review_prompt(diff: str) -> str:
    """Create the review prompt for the AI model."""
    architecture_context = read_architecture_context()

    # Log minimal diff details
    diff_lines = diff.count('\n')
    diff_length = len(diff)
    print(f"Diff size: {diff_lines:,} lines, {diff_length:,} characters", file=sys.stderr)

    # Truncate diff if it's too large to avoid API limits
    max_diff_length = 5000  # Conservative limit for diff content
    if diff_length > max_diff_length:
        print(
            f"WARNING: Diff is very large ({diff_length:,} chars), truncating to {max_diff_length:,} chars", file=sys.stderr)
        diff = diff[:max_diff_length] + "\n... (diff truncated due to size)"

    return f"""You are a helpful and diligent code assistant. Review the following unified diff and provide line-by-line feedback for specific issues.

    TASK
    Review the unified diff below and return feedback **only** on lines that were *added* or *modified*.

    ARCHITECTURE CONTEXT
    {architecture_context}

    OUTPUT
    Return a JSON array.  Each element **must** follow this exact schema:
    {{
        "path": "<file path from diff header>",
        "line": <line number in the *new* file>,
        "comment": "<concise actionable issue>"
    }}
    Return `[]` if no issues.

    COMMENT‑WORTHY ISSUES
    - Bugs / logic errors
    - Security vulnerabilities
    - Performance or memory leaks
    - Maintainability / readability problems
    - Violations of existing architectural patterns

    RULES
    1. Comment only on `+` lines (added or modified).
    2. Skip unchanged (` `) and removed (`-`) lines.
    3. One problem → one JSON object.  No duplicates.
    4. Keep comments short (<20 words) and specific.
    5. Do not wrap output in Markdown or extra text—*JSON only*.

    DIFF TO REVIEW
    ```diff
    {diff}
```"""


def should_use_claude(diff: str, has_important_label: bool, line_threshold: int = 0) -> bool:
    """Determine if we should use Claude based on PR characteristics."""
    # Always use Claude if the PR has "important changes" label
    if has_important_label:
        print("Using Claude due to 'important changes' label", file=sys.stderr)
        return True

    # Use Claude if the diff is large (over threshold)
    diff_lines = diff.count('\n')
    added_removed_lines = len(
        [line for line in diff.split('\n') if line.startswith(('+', '-'))])

    if added_removed_lines > line_threshold:
        print(
            f"Using Claude due to large diff: {added_removed_lines} lines > {line_threshold} threshold", file=sys.stderr)
        return True

    print(
        f"Using o3-mini for small diff: {added_removed_lines} lines <= {line_threshold} threshold", file=sys.stderr)
    return False


def get_ai_review(model: str, diff: str) -> str:
    """Get AI review for the given diff using specified model."""
    prompt = create_review_prompt(diff)

    if model == "claude-sonnet-4-20250514":
        api_key = os.environ.get('ANTHROPIC_API_KEY', '')
        if not api_key:
            print('ANTHROPIC_API_KEY not found', file=sys.stderr)
            return '[]'

        payload = create_claude_payload(model, prompt)
        return call_claude_api(api_key, payload)
    else:
        api_key = os.environ.get('OPENAI_API_KEY', '')
        if not api_key:
            print('OPENAI_API_KEY not found', file=sys.stderr)
            return '[]'

        payload = create_openai_payload(model, prompt)
        return call_openai_api(api_key, payload)


def filter_github_files_from_diff(diff: str) -> str:
    """Filter out .github files from the diff content."""
    lines = diff.split('\n')
    filtered_lines = []
    skip_file = False

    for line in lines:
        if line.startswith('diff --git'):
            # Check if this is a .github file
            parts = line.split()
            if len(parts) >= 4:
                file_path = parts[3][2:]  # Remove "b/" prefix
                if file_path.startswith('.github/'):
                    skip_file = True
                    print(
                        f"Filtering out .github file from AI review: {file_path}", file=sys.stderr)
                    continue
                else:
                    skip_file = False

        if not skip_file:
            filtered_lines.append(line)

    return '\n'.join(filtered_lines)


if __name__ == "__main__":
    # Get environment variables
    diff_b64 = os.environ.get('DIFF_B64', '')
    model = os.environ.get('MODEL', '')
    has_important_label = os.environ.get(
        'HAS_IMPORTANT_LABEL', 'false').lower() == 'true'
    line_threshold = int(os.environ.get('LINE_THRESHOLD', '0'))

    if not diff_b64:
        print('Missing required environment variable: DIFF_B64', file=sys.stderr)
        sys.exit(1)

    # Decode diff
    diff = base64.b64decode(diff_b64).decode('utf-8')

    # Filter out .github files from diff
    diff = filter_github_files_from_diff(diff)

    # Check if there's any meaningful diff left after filtering
    if not diff.strip() or not any(line.startswith('diff --git') for line in diff.split('\n')):
        print(
            "No significant files to analyze after filtering .github files", file=sys.stderr)
        review_b64 = base64.b64encode("[]".encode('utf-8')).decode('utf-8')
        
        # Write output to GitHub Actions output file
        if 'GITHUB_OUTPUT' in os.environ:
            with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
                fh.write(f"review_b64={review_b64}\n")
        else:
            # Fallback for local testing
            print(f"review_b64={review_b64}", file=sys.stderr)
        sys.exit(0)

    # Determine which model to use based on labels and diff size
    if should_use_claude(diff, has_important_label, line_threshold):
        selected_model = "claude-sonnet-4-20250514"
        model_comment = "This response was generated by Claude 4 Sonnet."
    else:
        selected_model = "o3-mini"
        model_comment = "This response was generated by o3 mini."

    # Override with provided model if specified
    if model:
        selected_model = model
        print(f"Using model override: {selected_model}", file=sys.stderr)

    print(f"Selected model: {selected_model}", file=sys.stderr)

    # Get review
    review = get_ai_review(selected_model, diff)

    # Output base64 encoded review and model info
    review_b64 = base64.b64encode(review.encode('utf-8')).decode('utf-8')
    
    # Write output to GitHub Actions output file
    if 'GITHUB_OUTPUT' in os.environ:
        with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
            fh.write(f"review_b64={review_b64}\n")
            fh.write(f"model_used={selected_model}\n")
            fh.write(f"model_comment={model_comment}\n")
    else:
        # Fallback for local testing
        print(f"review_b64={review_b64}", file=sys.stderr)
        print(f"model_used={selected_model}", file=sys.stderr)
        print(f"model_comment={model_comment}", file=sys.stderr)
