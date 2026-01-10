# Playwright Function App

## Principles

- Minimalist design for the core project
- Use "sidecar" containers for features where possible. i.e.
  - VSCode to edit the scripts locally
  - GitSync to sync a script repo for remote editing
  - UptimeKuma or cronicle for scheduling

## Deployment options

- Docker Compose with GitSync or VSCode
- Unraid docker with GitSync or VSCode
- Use https://playwright.dev/docs/docker

## Functions

- Multi-proc (or workers)
  - Script detector should be a child proc. A filed load should not affect the current loaded scripts, or the main proc.
  - Each script execution should be a child proc, to protect the main proc. Possibly a direct execution of the playwright CLI.
- Build a script directory in memory
  - Scan for scripts at startup, file watcher, polling
  - Dictionary of `{path}/{fileName}/{function}` => function()
  - Each file should export a register function:
    ```typescript
    // filename: foo/bar.ts
    export register() {
        return {
            'pingGoogle': pingGoogle,
            'checkSyncthing': checkSyncthing,
        }
    }
    // The resulting global file lookup directory would be:
    {
        'foo/bar/pingGoogle': 'foo/bar.ts',
        'foo/bar/checkSyncthing': 'foo/bar.ts',
        // ... other files
    }
    // The resulting local function lookup directory would be:
    {
        'foo/bar/pingGoogle': pingGoogle,
        'foo/bar/checkSyncthing': checkSyncthing,
        // no other files
        // local only, not kept in main proc
    }
    ```
- Invoke via url path
  - `/fn/{fileName}/{function}`
  - Only lookup via the "directory", never go directly to the file system
  - Provide access to the request object for query string / body usage
  - Return type:
    - Customize the response via a return object
      ```typescript
      interface ScriptResponse {
        success: boolean;
        statusCode: number;
        body?: JSON;
        error?: JSON;
      }
      ```
    - Default return of nothing is equivalent to  
      `{ success: true, statusCode: 200 }`
    - Throwing an exception is equivalent to  
      `{ success: false, statusCode: 500 }`
      - Include an option to include error details (INSECURE)  
        `{ ..., error: ex.toString() }`
- Detailed logs of the most recent run of each script
  - Don't log keyboard commands, to prevent accidental secret logging
  - Provide option for capturing screenshots
  - No history, only current run
- Maybe implement OpenTelemetry so an external system could keep metrics
