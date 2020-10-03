# csv_bash
Powerfull Bash script to handle csv files (view, search, edit, replace, save, etc...)

## Example
- Content of the test file :
```
ID;NAME;AGE;CITY
1;Mathieu;35;Bordeaux
2;Gertrude;102;Soulac
```

- Test commands :
```
bash
. csvedit.sh my_file.csv

Commands list :
help            Print this help
file            Print working file name
find            Find rows by column value
find_one        Same as above, returns only the first occurence found
limit           Limits the number of results
get             Get the values of the selected column
set             Set the values of the selected columns
new             Create a new line
save            Save the lines in the working file
delete          Delete the lines
headers         Print the headers names
column_add      Add a column
column_delete   Remove a column


find
1;Mathieu;35;Bordeaux
2;Gertrude;102;Soulac

find ID 1 | set AGE 55 | set NAME Bastian | save
1;Bastian;55;Bordeaux

find
1;Bastian;55;Bordeaux
2;Gertrude;102;Soulac
```
