# Selected authentication routes

This is a list of useful API endpoints provided by the Devise and Doorkeeper gems. For more details about the implementation of OAuth in Panoptes, please see their documentation.

## Get a token via client credentials

```http
POST /oauth/token HTTP/1.1
Content-Type: application/json

{
  "grant_type": "client_credentials",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```

Obtain a new token via a client ID and secret.

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "token_type": "Bearer",
  "expires_in": 7200,
  "refresh_token": "re-freshtokenakjsdfdsfw334rsefdjfh",
  "scope": "user project group collection classification subject medium organization translation public",
  "created_at": 5573462601
}
```

## Get a token via password

```http
POST /oauth/token HTTP/1.1
Content-Type: application/json

{
  "grant_type": "password",
  "client_id": "f79cf5ea821bb161d8cbb52d061ab9a2321d7cb169007003af66b43f7b79ce2a",
  "login": "username",
  "password": "password"
}
```

Obtain a new token using a login and password. A client ID is required for logging in, but the corresponding secret is not. The client ID below is used by our various clients (JS, python, ruby) and can be used directly with the production API.

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "token_type": "Bearer",
  "expires_in": 7200,
  "refresh_token": "re-freshtokenakjsdfdsfw334rsefdjfh",
  "scope": "user project group collection classification subject medium organization translation public",
  "created_at": 5573462601
}
```

## Get logged in user information

```http
GET /api/me HTTP/1.1
Content-Type: application/json
Accept: application/vnd.api+json; version=1
Authorization: Bearer eyTokenTokenTokenasdfasdf
```

Retrieve user information via valid token.

```json
{
  "users": [
    {
      "id": "9999999",
      "login": "username",
      "display_name": "Username",
      "credited_name": "Username Usernamerson",
      "email": "email@example.org",
      "languages": [],
      "created_at": "2016-04-18T19:12:22.343Z",
      "updated_at": "2026-03-02T19:51:04.868Z",
      "type": "users",
      "global_email_communication": true,
      "project_email_communication": false,
      "beta_email_communication": true,
      "nasa_email_communication": false,
      "subject_limit": 1000000,
      "uploaded_subjects_count": 258663,
      "admin": true,
      "href": "/users/9999999",
      "login_prompt": false,
      "private_profile": true,
      "zooniverse_id": "panoptes-9999999",
      "upload_whitelist": true,
      "avatar_src": null,
      "valid_email": true,
      "ux_testing_email_communication": false,
      "intervention_notifications": true,
      "banned": false,
      "confirmed_at": "2024-01-25T17:33:01.000Z",
      "links": {}
    }
  ],
  "links": {
    "users.classifications": {
      "href": "/classifications?user_id={users.id}",
      "type": "classifications"
    },
    "users.project_preferences": {
      "href": "/project_preferences?user_id={users.id}",
      "type": "project_preferences"
    },
    "users.collection_preferences": {
      "href": "/collection_preferences?user_id={users.id}",
      "type": "collection_preferences"
    },
    "users.projects": {
      "href": "/projects?owner={users.login}",
      "type": "projects"
    },
    "users.collections": {
      "href": "/collections?owner={users.login}",
      "type": "collections"
    },
    "users.recents": {
      "href": "/users/{users.id}/recents",
      "type": "recents"
    },
    "users.avatar": {
      "href": "/users/{users.id}/avatar",
      "type": "media"
    },
    "users.profile_header": {
      "href": "/users/{users.id}/profile_header",
      "type": "media"
    }
  }
}
```

## Unsubscribe a user from all emails

```http
POST /users/password HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "user": {
    "email": "user@example.org"
  }
}
```

Unsubscribes a user from receiving Zooniverse newsletters. Returns an empty 200 when successful.

