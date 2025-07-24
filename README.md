# Flatpak Build Files for Frappe Books

Frappe Books is a free desktop book-keeping software for small businesses and freelancers.


## Update Flatpak

```bash
# checkout to new branch from master

git checkout -b new-update

# dependencies: jq, curl, yq
./update-manifest.sh

# update the appdata file with new changelog entry
$EDITOR io.frappe.books.appdata.xml

# Commit & push the new branch to remote
git push
```

- Create a PR against `master` branch
- the CI/CD process starts building the flatpak on all supported architectures
- On a successful build, You can merge the PR

## To build & test the flatpak locally

```bash
chmod +x build-flatpak.sh
./build-flatpak.sh
```
