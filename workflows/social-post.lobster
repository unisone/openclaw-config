name: social-post
description: "Post to social media with human approval gate. Agent drafts, human approves, then it posts."

args:
  platform:
    type: string
    required: true
    description: "Target platform (x, linkedin)"
  content:
    type: string
    required: true
    description: "Post content / draft text"
  reply_to:
    type: string
    required: false
    description: "Tweet/post URL to reply to (optional)"

steps:
  - id: draft-review
    approval: required
    prompt: "📝 Post to {{platform}}:\n\n{{content}}\n\n{{#reply_to}}Replying to: {{reply_to}}{{/reply_to}}\n\nApprove this post?"

  - id: publish
    action: exec
    command: |
      node ~/openclaw-workspace/scripts/posting-gate/post.js \
        --platform "{{platform}}" \
        --content "{{content}}" \
        {{#reply_to}}--reply-to "{{reply_to}}"{{/reply_to}}
