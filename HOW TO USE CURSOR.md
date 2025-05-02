<think>The user is asking how they can give me access to their full project codebase every time they ask for help, which would allow me to have more context and make better decisions.

This is a good question about workflow. The user wants to establish a more efficient way to collaborate where I have full context of their project rather than getting limited snippets each time.</think>Good morning! Having access to your entire codebase provides much better context for helping you. Here are a few effective ways to give me access to your full project each time:

### Within Cursor IDE

1. **Use the Workspace Context**:
   - Cursor automatically provides some context about your workspace when you start a conversation
   - This includes open files, cursor position, and recent views

2. **Use File Explorer Commands**:
   - You can type `/files` in the chat to share your project structure
   - This shows me the directory structure of your project

3. **Project Summary Command**:
   - Type `/project` to generate a summary of your project
   - This gives an overview of your codebase, key files, and structure

### For Deeper Context

4. **Create a Project Description File**:
   - Create a `PROJECT_OVERVIEW.md` file in your root directory
   - Include architecture details, main components, dependencies, and workflow
   - Refer to this file at the start of our conversations

5. **Share a Git Repository**:
   - If your project is on GitHub/GitLab, you can share a link
   - This allows me to understand the project's history and evolution

6. **Start Each Conversation with Context**:
   - Begin with "This is my Flutter app for surveying with [key features]"
   - Mention any recent changes or the current focus area

### Best Practice

The most effective approach is a combination:
1. Start our conversation with a brief reminder of the project
2. Use `/files` to show the structure
3. Tell me what specific problem you're working on

This allows me to quickly understand your project each time while focusing on your current need.

Would you like me to help you create a comprehensive `PROJECT_OVERVIEW.md` file for your surveying app that we can reference in future conversations?
