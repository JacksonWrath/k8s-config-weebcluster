### Cookies ConfigMap

The cookie for Patreon needs to be periodically refreshed (~28 days I think), so I'm updating that with a script that runs on my desktop on startup. It grabs the current session_id cookie and updates a ConfigMap (example below). gallery-dl merges multiple configs together.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: patreon-cookie
data:
  patreon_cookie.json: |
    {
        "extractor": {
            "patreon": {
                "cookies": {
                    "session_id": "..."
                }
            }
        }
    }
```