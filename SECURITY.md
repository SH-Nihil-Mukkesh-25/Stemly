# Security Policy

The Stemly team takes security seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.2.x (latest) | Yes |
| 0.1.x | Security fixes only |
| < 0.1.0 | No |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email:

- **Email**: [stemly.team@gmail.com](mailto:stemly.team@gmail.com)
- **Subject line**: `[SECURITY] <brief description>`

### What to Include

Please include as much of the following information as possible to help us understand and resolve the issue:

- **Type of vulnerability** (e.g., SQL injection, XSS, authentication bypass, data exposure)
- **Location** of the affected source code (file path, branch, or commit)
- **Steps to reproduce** the issue
- **Proof of concept** or exploit code (if available)
- **Impact assessment** — what an attacker could achieve
- **Suggested fix** (if you have one)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within **48 hours**
- **Assessment**: We will provide an initial assessment within **1 week**
- **Resolution**: We aim to release a fix within **30 days** for critical issues
- **Credit**: We will credit you in the fix release (unless you prefer to remain anonymous)

## Security Best Practices for Contributors

When contributing to Stemly, please follow these security guidelines:

### Secrets and Credentials

- **Never** commit API keys, passwords, tokens, or service account keys
- Use environment variables (`.env` files) for all secrets
- Ensure `.env` and credential files are listed in `.gitignore`
- If you accidentally commit a secret, rotate it immediately and notify the maintainers

### Authentication and Authorization

- All API endpoints that access user data must require authentication
- Validate Firebase ID tokens on the backend for every authenticated request
- Never trust client-side authentication alone

### Input Validation

- Validate and sanitize all user inputs on both frontend and backend
- Use Pydantic models for request validation in FastAPI
- Never pass raw user input to database queries or system commands
- Be cautious with file uploads — validate file types and sizes

### Dependencies

- Keep dependencies up to date
- Review new dependencies before adding them — prefer well-maintained packages
- Run `pip audit` (Python) and check for known vulnerabilities regularly

### Data Protection

- Do not log sensitive user information (passwords, tokens, personal data)
- Use HTTPS for all API communication
- Follow the principle of least privilege for database access

### AI/LLM-Specific

- Sanitize inputs before sending to AI models to prevent prompt injection
- Do not expose raw AI model responses without validation
- Rate-limit AI API calls to prevent abuse

## Scope

This security policy applies to:

- The Stemly GitHub repository and all its code
- The deployed Stemly backend API
- The Stemly mobile/web application

Out of scope:

- Third-party services (Firebase, Google Gemini, MongoDB Atlas) — report to those providers directly
- Issues in dependencies — report upstream, but do let us know so we can update

## Recognition

We gratefully acknowledge security researchers who help keep Stemly and its users safe. With your permission, we will list your name here:

*No reports yet — be the first to help secure Stemly!*
