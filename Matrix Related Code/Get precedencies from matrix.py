##################
# IMPORT LIBRARIES
##################

import pandas as pd
import ast
import itertools

##################
# PREPARE DATA
##################
""" 
Two excel files will be imported.

An excel file that must have two columns, that are calculated from the task-competency matrix:
- a column with the set of competencies assigned to each task, 
where each set is of the form [competencyIDx,competencyIDy,...]
(the name given to this column in the present document is 'Minimal Subset of Competencies')
- a column with the number of competencies in each of those sets 
(the name given to this column in the present document is 'Nr Of Items')

An excel file with two columns regarding the competencies in the domain.
- a column with the competency ID
(the name given to this column in the present document is 'CompetencyID')
- a column with the description of the competency
(the name given to this column in the present document is 'CompetencyDescription')
"""
minimal_subsets_col_name = 'Minimal Subset of Competencies'
nr_items_col_name = 'Nr Of Items'
skill_ID_col_name = 'Competency ID'
skill_desc_col_name = 'Competency Description'

# import competencies data
excel_matrix_path = r'path\file_name.xlsx'
excel_matrix_sheet = 'sheet_name'
skills_data = pd.read_excel (excel_matrix_path, sheet_name = excel_matrix_sheet)

skill_IDs = skills_data[skill_ID_col_name].astype(int)
skill_desc = skills_data[skill_desc_col_name]

# import matrix related data
excel_matrix_path = r'path\file_name.xlsx'
excel_matrix_sheet = 'sheet_name'
data = pd.read_excel (excel_matrix_path, sheet_name = excel_matrix_sheet)
initial_nr_rows = data.shape[0]

# sort the dataframe by the number of items in each minimal subset of competencies
data.sort_values(by=nr_items_col_name, inplace=True)

# drop rows with duplicated minimal subset of competencies
data.drop_duplicates(subset=minimal_subsets_col_name, inplace=True)
print('{} rows were dropped from the dataframe as they represented duplicated minimal subsets.'.format(initial_nr_rows-data.shape[0]))

# save all the minimal subsets in a list. Each minimal subset is seen as a string (e.g. '[74,75]')
subsets_str = list(data[minimal_subsets_col_name])

# convert the list of strings into a list of sets for better performance (order is not important)
subsets_list = [set(ast.literal_eval(i)) for i in subsets_str]

# save all competency/skill IDs (they go from 1 to 77 in this order so range() will be used)
skills = list(range(1, 78, 1))

#############################################
#APPLY RULE AND STORE THE PRECEDENCIES FOUND
#############################################
"""
The precedence rule is: 
A prerequisite relationship is always assumed between two competencies when only one is present
when the other is also present.
"""
# create dictionary to save the encountered precedencies
# the keys will be the skills which have antecedents (skills that need to be mastered before)
# the values will be the the set of antecedents for each skill
confirmed_precedencies = {}

# iterate over each skill to check if each skill has any prerequisite skills
for skill in skills:
    # get list of lists only with the subsets where the skill exists
    skill_list = [x for x in subsets_list if skill in x]

    counter = 0
    # iterate over the skill_list created above
    while counter < len(skill_list):
        # get subset in the index = counter, the analysis will be done subset by subset
        subset_under_analysis = skill_list[counter]

        counter+=1
        # having the subset under analysis, iterate over the other subsets to see if any skill exists in all of them
        for list_iterate in skill_list:
            # confirm subset_under_analysis is not empty
            if subset_under_analysis: 
                # keep in the subset_under_analysis only the skills that are common, these are the ones with potential to be prerequisites
                subset_under_analysis = list(set(subset_under_analysis).intersection(list_iterate))
                
        # remove the skill in question from the subset, this skill will be in all subsets
        subset_under_analysis.remove(skill)

        # if at the end of the iterations, subset_under_analysis is not empty
        # it means precedences were encountered and now they will be added to the final dictionary
        if subset_under_analysis:
            # create empty set as the value associated to the key skill
            confirmed_precedencies[skill] = set()
            # add to the set the encountered precedences
            [confirmed_precedencies[skill].add(x) for x in subset_under_analysis]


# print the encountered precedencies
# the key is the consequent and the values in the value are its antecedents
print(confirmed_precedencies)

#######################################
# SAVE THE PRECEDENCIES IN EXCEL FILE
#######################################

# create dataframe with the surmise relations discovered (with skill descriptions and IDs and the relation as a binary tuple)
df_prec = pd.DataFrame(columns = ['Antecedent', 'Consequent', 'Antecedent_ID', 'Consequent_ID','Surmise_Relation'])
for key, value in confirmed_precedencies.items():
    index_key = skill_IDs[skill_IDs == key].index[0]
    
    for item in value:
        index_value = skill_IDs[skill_IDs == item].index[0]
        df_prec = df_prec.append({'Consequent' : skill_desc[index_key], 'Antecedent' : skill_desc[index_value], 'Antecedent_ID': skill_IDs[index_value], 'Consequent_ID': skill_IDs[index_key], 'Surmise_Relation': (skill_IDs[index_value], skill_IDs[index_key])}, ignore_index = True)    


# save dataframe with surmise relations encountered to excel (they will be validated by the experts)
output_path = r'path\file_name.xlsx'
df_prec.to_excel(excel_writer=output_path, index=True)
