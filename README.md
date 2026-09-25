# Shiori Brain 🌸

Shared, versioned knowledge for Dragonshorn Studios coding agents.

AFFiNE is the source of truth. The `Sync AFFiNE knowledge` workflow exports the
linked document graph rooted at **Shared Architecture — Start Here**, opens an
update pull request, and generates installable skills and marketplaces for the
supported coding agents.

Do not edit generated files by hand. Change the source documents in AFFiNE and
run the sync workflow instead.

## Repository settings

Configure these GitHub Actions values:

- Variable `AFFINE_BASE_URL`
- Variable `AFFINE_WORKSPACE_ID`
- Variable `AFFINE_ROOT_DOCUMENT_ID`
- Secret `AFFINE_EMAIL` — dedicated AFFiNE service-account email
- Secret `AFFINE_PASSWORD` — dedicated AFFiNE service-account password

This repository exports workspace `82dbcbba-c52a-4539-be3f-133ea6ebcb9d`
from root document `j4IXQ9l6wz` (`Shared Architecture — Start Here`).

The sync can then be started from **Actions → Sync AFFiNE knowledge → Run
workflow**. After the generated pull request is merged, the Pages workflow
publishes the browsable archive.
