# Bank Scripts

## Getting Started - NordicAPIGateway

1. Ruby and Bundler:

  a. The script is written in Ruby and tested on version `2.3.7`.

  b. To install dependencies first install [Bundler](https://bundler.io).

  c. Run `bundle install` in the root folder.

2. [Nordic API Gateway](https://www.nordicapigateway.com):

  a. Create an account and a new app.

  b. Copy `CLIENT ID` and `CLIENT SECRET` into `nordicapigateway.rb`, replacing current values for `NORDIC_API_GATEWAY_CLIENT_ID` and `NORDIC_API_GATEWAY_CLIENT_SECRET` keys respectively.

3. Database:

  a. The script works with PostgreSQL database.

  b. To configure connection to the database change keys prefixed with `DATABASE_` in `pull.rb`.

  > For local database easiest to use [Postgres.app](https://postgresapp.com) with [Postigo](https://eggerapps.at/postico/) GUI client.

  > Existing keys connect to local database with name 'nordicapigateway'. Database must be created manually.

## Usage

1. Open Terminal app.

2. Navigate to a folder with the script (e.g. `cd NordicAPIGateway-scripts`).

3. Run the script `./pull.rb`:

  a. It will open an authentication url in the default browser.

  b. Choose bank and login with your credentials.

  > For test account choose any bank and enter any digits for username and password.

  c. It should open another page with json and the code.

  Example of the json response:

  ```
  "args": {
     "code": "the_code_to_copy"
  },
  ...
  ```

  d. Copy the code and paste in the terminal, then press Enter. At this point the script will be asking for the code.

  e. Then it will authenticate and prepare for loading data.

  f. Optionally enter company id to link transactions with. Accepts any string.

  g. The script will print available accounts.

  Example of available accounts:

  ```
  Available accounts:
  0 - Checking Account DKK
  1 - Direct Debit DKK
  ```

  Choose one by entering its number and pressing Enter.

  h. The script will pull transactions for the account and store them in the database.
