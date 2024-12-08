# Starlite Action (alpha)

This Action allows you to push a service catalog record and standards (checks) results to Starlite.

## Setup and usage

You need to set a required secret for an API key, then you are greenlit to just start using the action!

### Updating the record

The record (service catalog) step requires you to have a `manifest.json` file on disk.

Please see the [Catalogist documentation](https://github.com/mikaelvesavuori/catalogist#manifest) for more details.

### Running the standards check

For the standards check to run and results to be sent, the only thing you need to run this action is a `standardlint.json` configuration file in your root directory.

Please see the [StandardLint documentation](https://github.com/mikaelvesavuori/standardlint#configuration) for more details.

### Security

Always ensure you have secure settings regarding what actions you allow.

## Required input arguments

### `api-key`

Starlite API key.

## Example of how to use this action in a workflow

```yml
on: [push]

jobs:
  starlite:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # Do your things here: build, test, deploy...

      - name: Run Starlite action (alpha)
        uses: starlite/starlite-alpha@v0
        with:
          api-key: ${{ secrets.STARLITE_API_KEY }}
          org-id: 'demoorg'
          record-id: 'demorecord'
```
