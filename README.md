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

Liste des commandes :
help            Affiche l'aide
file            Affiche le fichier de travail
find            Recherche par valeur d'une colonne
find_one        Idem recherche mais ne renvoi que la premiere ligne
limit           Limite le nombre des resultats
get             Retourne la valeur du champ des ligness
set             Modifie la valeur du champs dans les lignes
new             Creer une nouvelle ligne
save            Enregistre les lignes dans le fichier de travail
delete          Supprime les lignes
rows            Affiche les entetes des colonnes
row_add         Ajoute une colonne
row_delete      Supprime une colonne


find
1;Mathieu;35;Bordeaux
2;Gertrude;102;Soulac

find ID 1 | set AGE 55 | set NAME Bastian | save
1;Bastian;55;Bordeaux

find
1;Bastian;55;Bordeaux
2;Gertrude;102;Soulac
```
