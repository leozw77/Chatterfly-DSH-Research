# Security

This repository documents a local integration between Chatterfly and DeepSeek Harness.

Please do not open issues or pull requests containing:

- DeepSeek API keys;
- Chatterfly local tokens;
- raw credential stores;
- full DSH session logs containing private prompts or files;
- proprietary Tencent binaries/packages.

If you use the task probe, it redacts fields named token, authorization, api_key, and apikey before writing JSON logs.

The project does not attempt to bypass Chatterfly authentication. Authentication artifacts are treated as opaque.
