# csv_bash
Powerfull Bash script to handle csv files (view, search, edit, replace, save, etc...)

## Example
- Example file :
```
ID,NAME,AGE,CITY
1,Alex,35,Paris
2,Sam,102,NY
```

- Test commands :
```
bash
. csv_bash.sh my_file.csv

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
c_add           Add a column
c_delete        Remove a column


find
1,Alex,35,Paris
2,Sam,102,NY

find ID 1 | set AGE 55 | set NAME Bastian | save
1,Bastian,55,Paris

find
1,Bastian,55,Paris
2,Sam,102,NY
```
