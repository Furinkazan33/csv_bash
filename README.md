# csv_bash
Powerfull Bash script to handle csv files (view, search, edit, replace, save, etc...)

## Example
```
ID;NAME;AGE;CITY
1;Mathieu;35;Bordeaux
2;Gertrude;102;Soulac
```

```shell
. csvedit test.csv
find
find ID 1 | set AGE 55
```
