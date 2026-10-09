# Stock Opname

Static web application for stock-opname reconciliation. GitHub Actions publishes it to GitHub Pages whenever a commit is pushed to `main`. Supabase provides staff authentication and shared team data.

## Publish with GitHub Pages

1. Create a GitHub repository and add this project to it.
2. Make sure the deployment workflow and `index.html` are committed on the `main` branch.
3. In the repository, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions**. This one-time setting must be enabled by a repository administrator.
4. Push a commit to `main`, or run **Deploy to GitHub Pages** from the repository's **Actions** tab.
5. Once the workflow succeeds, open the Pages URL shown in the deployment job (normally `https://<account>.github.io/<repository>/`).

The workflow packages only `index.html` for publishing. The spreadsheet parser is loaded from jsDelivr, so users need an internet connection to use workbook import/export features.

## Supabase authentication and shared data

The browser app uses the Supabase project URL and publishable key in `index.html`. A publishable key is intended for browser use; never put a Supabase secret or `service_role` key in this repository.

1. In Supabase **Authentication → Settings**, disable public sign-ups.
2. In **Authentication → URL Configuration**, set **Site URL** to `https://projectme-maz.github.io/gjm/` and add that same address under **Redirect URLs**.
3. Open **SQL Editor → New query**, paste the contents of [`supabase-setup.sql`](./supabase-setup.sql), and click **Run**. This creates the shared-state table and restricts it to authenticated users.
4. In **Authentication → Users**, use **Invite user** to add each staff member by email. The invitation link opens the app so the staff member can set a password.
5. Open the deployed GitHub Pages URL and log in with the invited account.
6. The first successful login creates the shared workspace record. If this browser has existing locally saved app data, that data is used to initialize the shared record. Back up important data before setup.

Authenticated staff share one workspace dataset. Changes are saved to Supabase and other open sessions check for updates every eight seconds. Data is no longer limited to the local browser after the shared record has been initialized.

The SQL does not grant database access to anonymous visitors and does not allow authenticated users to delete the shared record. Anyone you invite can read and edit the shared stock-opname data; invite only trusted staff.
