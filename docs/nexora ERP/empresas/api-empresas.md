# API de Empresas e Multi-Tenant

## Companies

### POST /api/companies
### GET /api/companies
### GET /api/companies/{id}
### PUT /api/companies/{id}

## Company Settings

### POST /api/companies/{id}/settings
### GET /api/companies/{id}/settings
### PUT /api/companies/{id}/settings/{settingId}

## Branches

### POST /api/companies/{id}/branches
### GET /api/companies/{id}/branches
### GET /api/branches/{id}
### PUT /api/branches/{id}

## Addresses

### POST /api/companies/{id}/addresses
### GET /api/companies/{id}/addresses

## Contacts

### POST /api/companies/{id}/contacts
### GET /api/companies/{id}/contacts

## Documents

### POST /api/companies/{id}/documents
### GET /api/companies/{id}/documents

## Tax Info

### POST /api/companies/{id}/tax-info
### GET /api/companies/{id}/tax-info
### PUT /api/companies/{id}/tax-info

## Banks

### POST /api/companies/{id}/banks
### GET /api/companies/{id}/banks

## Licenses

### POST /api/companies/{id}/licenses
### GET /api/companies/{id}/licenses

## Company Users

### POST /api/companies/{id}/users
### GET /api/companies/{id}/users
### DELETE /api/companies/{id}/users/{userId}
