# COBOL Moneybags

The auditor asked to see the movement of funds.

![Two shaded moneybags tossing a coin back and forth while their balances change](moneybags.gif)

Each time the coin lands, the program transfers $100 between two packed-decimal (`COMP-3`) accounts. The bags grow and shrink with their balances. Every frame checks that the accounts still add up to $1,000.00.

## Run it

Use GnuCOBOL and a UTF-8 terminal with 256-color support. An 80×24 window is enough.

```sh
cobc -free -O2 -x moneybags.cob && ./moneybags
```

The entire renderer lives in [moneybags.cob](moneybags.cob). It revolves a radius profile into a sack, shades the folds and dollar sign, and draws two vertical pixels per terminal cell with `▀`. After eight transfers, the batch closes.
