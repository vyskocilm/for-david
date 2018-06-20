# The test

How to run it

```
CONNECTION_URL="pgsql:/user@database" ./r
```

It will initialize cusomers and customer_inventory tables, run the import
script and test the results.

Assumption: user/database exists, user MUST be able to drop and create tables in database.


