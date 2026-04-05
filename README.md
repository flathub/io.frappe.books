# Flatpak Build Files for Frappe Books

Frappe Books is a free desktop book-keeping software for small businesses and freelancers.

## Automated Updates

A [GitHub Actions workflow](.github/workflows/check-for-updates.yml) runs **weekly on Mondays at 09:00 UTC** and automatically:

1. Checks if a new upstream release is available on the [frappe/books](https://github.com/frappe/books) repository
2. Downloads the release artifacts and computes their SHA256 checksums
3. Updates `io.frappe.books.yml` with the new version URLs and checksums
4. Inserts a new `<release>` entry into `io.frappe.books.appdata.xml`
5. Opens a Pull Request for human review

Once the PR is open, CI builds the flatpak on all supported architectures. **Review and merge the PR when CI passes.**

You can also trigger the workflow manually at any time from the [Actions tab](../../actions/workflows/check-for-updates.yml) using the "Run workflow" button.

## Manual Update

If you need to run an update outside of the automated workflow:

```bash
# Dependencies: jq, curl, wget, yq
# Checkout a new branch first
git checkout -b update-vX.Y.Z

./update-manifest.sh

# Review the changes made to both files
git diff

# Commit and push
git add io.frappe.books.yml io.frappe.books.appdata.xml
git commit -m "chore: update to vX.Y.Z"
git push
```

Then open a PR against `master` and merge when CI passes.

## Building & Testing Locally

```bash
chmod +x build-flatpak.sh
./build-flatpak.sh
```
