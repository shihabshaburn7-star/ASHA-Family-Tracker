# ASHA Family Tracker(for ASHA & community health workers)

A free web app for recording households and family members in your ward:
house no, house name, address, area, and per-member details (name, role,
gender, age, phone, Aadhar, job, health condition, pregnancy, and a full
child immunization schedule). Includes search, sort, filters, editing, and
PDF export.

**This app is designed to be shared.** Anyone can open it and create their
own free account — each account's households are completely private and
invisible to every other account, so a whole team of health workers can
use the same deployment without ever seeing each other's data. Hosting is
free (GitHub Pages) and the database is free (Supabase's free tier).

**⚠️ This app stores sensitive personal data (Aadhar numbers, phone numbers,
health information). Please read the "Security" section below before you
start entering real family details.**

---

## Part 1 — Create your free Supabase project (the database)

1. Go to https://supabase.com and sign up for a free account.
2. Click **New project**. Give it a name (e.g. "family-tracker") and a
   database password (save this password somewhere safe).
3. Once the project is ready, open **SQL Editor** in the left menu →
   **New query**. Open the file `supabase-schema.sql` from this folder,
   copy all of it, paste it into the editor, and click **Run**.
   This creates the two tables (`families`, `members`) and locks the data
   down so only a signed-in user can read or write it — and each signed-in
   user only ever sees their **own** households, never anyone else's.
4. You don't need to manually create logins — anyone using the app can
   click **"Create an account"** on the sign-in screen and set up their
   own login with just an email and password. (If you'd rather add
   people yourself instead of self-service sign-up, you still can, under
   **Authentication → Users → Add user**.)
   - For a **public deployment** that strangers could stumble onto,
     go to **Authentication → Providers → Email** and leave "Confirm
     email" **ON** — this stops someone from mass-creating accounts
     with fake addresses. For a small private team you control, you can
     turn it off for convenience.
5. Go to **Project Settings → API**. You'll need two values from this page:
   - **Project URL**
   - **anon public** key

## Part 1a — Turn on Google sign-in and one-time-code sign-in (optional)

The app already has the buttons for these built in — you just need to
switch them on in Supabase.

**Email one-time code (OTP)** — no extra setup needed. It uses the same
email sign-in Supabase already has on by default, just without a
password: the person enters their email, gets a 6-digit code, and types
it in. If you want to double check the email actually contains a typed
code (not just a "click to sign in" link), go to **Authentication → Email
Templates → Magic Link** and confirm `{{ .Token }}` appears somewhere in
the template — it does by default.

**Google sign-in** needs a one-time setup with Google:
1. Go to https://console.cloud.google.com/ → create a project (or use an
   existing one) → **APIs & Services → OAuth consent screen** → fill in
   the basic app info (name, support email) and publish it.
2. Go to **APIs & Services → Credentials → Create Credentials → OAuth
   client ID** → Application type: **Web application**.
3. Meanwhile, in Supabase, go to **Authentication → Providers → Google**
   and turn it on — it will show you a **Callback URL** (looks like
   `https://xxxxx.supabase.co/auth/v1/callback`).
4. Back in Google Cloud, paste that Supabase callback URL into
   **Authorized redirect URIs**, save, and copy the **Client ID** and
   **Client Secret** Google gives you.
5. Paste that Client ID and Client Secret into the Supabase Google
   provider screen and save.
6. Still in Supabase, go to **Authentication → URL Configuration** and
   add your GitHub Pages address (e.g.
   `https://your-username.github.io/asha-family-tracker/`) under **Redirect
   URLs**, so Google sends people back to the right place after signing in.

If you skip this section, the "Continue with Google" button will simply
show an error when tapped — email/password and email OTP sign-in still
work fine either way.

## Part 2 — Connect the app to your project

1. Open `config.js` in this folder.
2. Replace the two placeholder lines with your **Project URL** and
   **anon public** key from step 5 above. Save the file.

## Part 3 — Host it free on GitHub Pages

1. Create a new **public** GitHub repository (e.g. `family-tracker`).
2. Upload all the files from this folder (`index.html`, `style.css`,
   `app.js`, `config.js`) to that repository.
3. In the repository, go to **Settings → Pages**.
4. Under "Build and deployment", set **Source** to `Deploy from a branch`,
   choose the `main` branch and `/ (root)` folder, then **Save**.
5. After a minute, GitHub will show you a link like
   `https://your-username.github.io/family-tracker/` — that's your app.
   Open it, click **Create an account** (or sign in if you already have
   one), and start adding families. Share this same link with anyone
   else who should use it — each person just creates their own account.

You can also just open `index.html` directly in a browser (double-click
it) to use it locally without GitHub — GitHub Pages is only needed if you
want a link you can open from your phone or share with others.

---

## Security

- **Each account is private.** Row Level Security in the database means
  every household and member row is tagged to the account that created
  it, and the database itself refuses to return or modify another
  account's rows — this is enforced by Postgres, not just hidden in the
  app's interface, so it holds even if someone tampers with the page.
- **Nothing works without signing in.** The public API key embedded in
  the app's code only allows access to whichever account is currently
  signed in; it grants no access on its own.
- **Passwords** must be at least 8 characters, and sign-up asks for the
  password twice to catch typos. Forgot-password support is built in
  (via email link) so people aren't stuck if they lose access.
- **Local cache, cleared on sign-out.** To make the app feel instant, it
  keeps a copy of your records in the browser's local storage on the
  device you're using, tagged to your account ID, and refreshes it
  quietly in the background. This cache is automatically cleared the
  moment you sign out, and one account's cached copy is never shown to a
  different account signing in on the same device — even mid-session.
- **For public deployments**, a few extra Supabase settings are worth
  checking under Authentication → Providers → Email and Authentication →
  Rate Limits: keep "Confirm email" on, and consider enabling CAPTCHA
  protection (Supabase supports hCaptcha/Turnstile) if you expect strangers
  to find the link, to prevent automated mass sign-ups.
- Because the repository is public, anyone can see the *app's code*, but
  not the data inside it (the data lives in Supabase, behind each
  account's login).
- If you ever suspect a login has been compromised, go to Supabase →
  Authentication → Users, and either reset that user's password or
  delete the account.
- Consider checking with your local health department / program
  supervisor about any additional data-handling rules that apply to
  patient or beneficiary records in your area.

## Using the app

- **Signing in** — three ways to get in, all private per-person: email +
  password, a one-time 6-digit code emailed to you (no password to
  remember), or "Continue with Google" (if you set that up in Part 1a).
  All three lead to the same kind of account — whichever you use, only
  you can see the data you enter.
- **Add family** — enter house details, then add one or more members: name,
  a detailed relationship **role** (House Owner, Father, Mother, Wife,
  Husband's Sister, Wife's Father, and many more — matching how relations
  are described on ration cards), gender, **date of birth** (age is
  calculated automatically and always stays correct — you never re-enter
  it; babies under 1 year show their age in months instead of "0"),
  phone, Aadhar, job, and health condition. If gender is Female, you can
  also mark **Currently pregnant** and enter the pregnancy start date
  (LMP) — the current month of pregnancy is calculated automatically and
  keeps advancing on its own as time passes. For anyone under 18, an
  **immunization checklist** appears automatically (matching the standard
  BCG / OPV / Pentavalent / Rotavirus / PCV / fIPV / MR / JE / Vitamin A /
  DPT booster / TT-Td schedule) — enter the date each vaccine was given
  and it shows as a ✓ tick, or stays a ✗ cross if left blank. There's also
  a free-text field for any other or SIA/pulse-round doses. **Once a
  member turns 18, their immunization records are automatically and
  permanently deleted** — both from the app and from the database — the
  next time the app is opened, since that data is only relevant for
  children. This can't be undone, so make sure any information you still
  need (e.g. for a health record) is copied elsewhere before someone's
  18th birthday.
- **View & manage** — search (now also matches role, pregnancy status,
  and immunization status), sort by house name/no/area/newest, filter by
  area, filter by an age range (calculated from date of birth), filter to
  only people with a health condition, filter to only pregnant women, and
  edit or delete any household or member inline. The view shows the
  calculated **age** and, for children, a quick "x/34 ✓" immunization
  summary; click Edit to see or update the full checklist.
- **Export data** — download **PDF** files: alphabetical (A–Z or Z–A), by
  house no, grouped by (or filtered to) one area, by age group (presets
  like 1–18, or a custom range — calculated from date of birth), health
  conditions only, pregnant women only (with their auto-calculated
  month), a dedicated **immunization chart** (one row per child under 18,
  one column per vaccine, ✓/✗ — just like the printed schedule chart), or
  everything. Every PDF includes both the date of birth and the
  calculated age (and both the pregnancy start date and calculated
  month), so the numbers are always traceable back to the original dates.

## If you set this up before (important one-time step)

An earlier version of this app stored a plain "age" number instead of a
date of birth, and tracked only a single polio yes/no flag instead of the
full immunization schedule. If your Supabase project already has the old
tables, re-run `supabase-schema.sql` in the SQL Editor — it now includes
a safe migration that adds the new date-of-birth, pregnancy, and
immunization columns and removes the old ones, without deleting any of
your households. You'll just need to re-enter each person's date of
birth (and pregnancy start date, if relevant) once, since an exact birth
date can't be recovered from an age in years, and re-tick any vaccines
that were previously only marked with the old single polio flag.

## Separate data per login (important one-time step if upgrading)

As of this update, **every login now has its own private set of
households** — if two ASHA workers each have an account, neither one can
see the other's families. This didn't used to be the case: previously,
every signed-in user shared one common pool of data.

Re-run `supabase-schema.sql` to pick this up — it's safe to re-run and
won't delete anything. But if you already had households saved **before**
this update, they currently have no owner assigned, which means they'd
become invisible to everyone until you do one small manual step:

1. In Supabase, go to **Authentication → Users**, click your user, and
   copy its **User UID**.
2. Go to **SQL Editor → New query**, and run just this one line (with
   your real User UID pasted in):
   ```sql
   update families set user_id = 'PASTE-YOUR-USER-UID-HERE' where user_id is null;
   ```

After that, your existing households will show up again under your
login, and any new households — from you or anyone else who signs in —
will automatically stay private to whoever created them.

## Troubleshooting

- **"Almost there" screen on load** → `config.js` still has the
  placeholder text; paste in your real Supabase URL and key.
- **Can't sign in** → try "Create an account" if you haven't got one yet,
  or "Forgot your password?" to reset it. If sign-up seems to do nothing,
  check whether "Confirm email" is turned on for your project (see Part
  1, step 4) — you may need to click a link in your inbox first.
- **Data not saving / permission errors** → make sure you ran the full
  `supabase-schema.sql` script, and that you're signed in (not just on
  the login screen).
- **A household I had before is missing** → see "Separate data per
  login" above — it likely needs the one-time ownership fix.
