> This action requires that you've enabled [code scanning](https://help.github.com/en/github/finding-security-vulnerabilities-and-errors-in-your-code/enabling-code-scanning) (currently in beta).

# DeepCode Code Scanning Github Action

## What is it?

DeepCode Code Scanning Github Action allows to integrate DeepCode's bug finding capabilities within your code scanning pipeline. When a commit is triggered, [DeepCode](https://www.deepcode.ai) finds bugs and security vulnerabilities and report them as part of your repository's code scanning alerts.

## How to install and enable the action?

### Get the DeepCode token

- Here is a video how to get it:

   ![get-deepcode-token](https://user-images.githubusercontent.com/1632188/83912998-1bedd000-a76f-11ea-996c-222526962f6c.gif)

- If you prefer the text version, here is how to get the DeepCode token:

   1. [Login](https://www.deepcode.ai/cloud-login) with your DeepCode account.
   2. Under Account you can find a section **"Deepcode API tokens"**.
   3. Create a new token by clicking on *"Create new session token"*.
   4. Copy the token and use it to create a secret in your Github repository (next section).

### Create api key in github repository

- Here is a video how to get it:

  ![set-deepcode-token-secret](https://user-images.githubusercontent.com/1632188/83913383-afbf9c00-a76f-11ea-91d3-0e28ddc5496a.gif)

- If you prefer the text version, here is how to create the secret:

   1. Navigate to the Settings of your repository.
   2. Under Secrets create a new secret by clicking on the *"New secret"* button.
   3. The secret name should be `DEEPCODE_TOKEN`. Please note the capital letters and the underscore, this is important and will be used later when setting up the Github action.
   4. Paste the token value you copied earlier.
   5. Press *"Add secret"* and you are now ready to setup the Github action.

### Example usage

Create a file `.github/workflows/deepcode-analysis.yml` and insert the following snippet:

```yml
name: A DeepCode analysis

on:
  # Trigger the workflow on push or pull request, but only for the master branch
  push:
    branches:
      - master
  pull_request:
    branches:
      - master

jobs:
  Deepcode-Build:
    runs-on: ubuntu-latest

    steps:

    - name: Checkout
      uses: actions/checkout@v2

    - name: Perform DeepCode analysis
      uses: georgismitev/deepcode-code-scanning-analysis@master
      env:
        DEEPCODE_TOKEN: ${{ secrets.DEEPCODE_TOKEN }}

    - name: Upload report
      uses: github/codeql-action/upload-sarif@v1
      with:
        sarif_file: output.sarif
```

# Feedback and contact

- In case you need to contact us or you want to provide feedback, we love to hear from you - [here is how to get in touch with us](https://www.deepcode.ai/feedback).
- If you want to report an issue go [here](https://github.com/georgismitev/deepcode-code-scanning-analysis/issues/new).
