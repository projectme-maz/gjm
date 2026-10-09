# Stock Opname

Static web application for stock-opname reconciliation. The site is served directly from `index.html`; GitHub Actions publishes it to GitHub Pages whenever a commit is pushed to `main`.

## Publish with GitHub Pages

1. Create a GitHub repository and add this project to it.
2. Make sure the deployment workflow and `index.html` are committed on the `main` branch.
3. In the repository, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions**.
4. Push a commit to `main`, or run **Deploy to GitHub Pages** from the repository's **Actions** tab.
5. Once the workflow succeeds, open the Pages URL shown in the deployment job (normally `https://<account>.github.io/<repository>/`).

The workflow packages only `index.html` for publishing. The spreadsheet parser is loaded from jsDelivr, so users need an internet connection to use workbook import/export features.

## Data storage

The application stores its data in the browser's local storage. Data is specific to that browser and device; GitHub Pages does not synchronize it between users or devices. Export or back up important data before clearing browser storage.
