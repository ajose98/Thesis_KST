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
The excel file to be imported must have three columns, that are calculated from the task-competency matrix:

- a column with the set of competencies assigned to each task, 
where each set is of the form [competencyIDx,competencyIDy,...]
(the name given to this column in the present document is 'Minimal Subset of Competencies')

- a column with the number of competencies in each of those sets 
(the name given to this column in the present document is 'Nr Of Items')

- a column with the designation of the task, identifying each row
((the name given to this column in the present document is 'Task Designation'))
"""
minimal_subsets_col_name = 'Minimal Subset of Competencies'
nr_items_col_name = 'Nr Of Items'
tasks_designation_col_name = 'QuestionSQL_ID / SkillID'

# import data
excel_matrix_path = r'path\file_name.xlsx'
excel_matrix_sheet = 'sheet_name'
data = pd.read_excel (excel_matrix_path, sheet_name = excel_matrix_sheet)
initial_nr_rows = data.shape[0]

# sort the dataframe by the number of items in each minimal subset of competencies
data.sort_values(by=nr_items_col_name, inplace = True)

""" 
The variables all_minimal_subsets and tasks that will be created below
will only be used after the computation of the base.
"""

# save all the minimal subsets in a list. Each minimal subset is seen as a string (e.g. '[74,75]')
all_minimal_subsets = list(data[minimal_subsets_col_name])
# convert the list of strings into a list of sets for better performance (also, order is not important)
all_minimal_subsets = [set(ast.literal_eval(i)) for i in all_minimal_subsets]

# save the number of competencies in each subset
# (the association can be made through the indexes of the 2 lists)
subsets_nr_items = list(data[nr_items_col_name])

# save the designation of the tasks associated to each minimal subset 
# (the association can be made through the indexes of the 2 lists)
tasks = list(data[tasks_designation_col_name])

# drop rows with duplicated minimal subset of competencies
data.drop_duplicates(subset = minimal_subsets_col_name, inplace = True)
print('{} rows were dropped from the dataframe as they represented duplicated minimal subsets.'.format(initial_nr_rows-data.shape[0]))

"""
The code used to create the variable all_minimal_subsets will be reused to create the variable
subsets_list, but now there will be no duplicates in the list and it will be ordered.
"""
# save all the minimal subsets in a list. Each minimal subset is seen as a string (e.g. '[74,75]')
subsets_str = list(data[minimal_subsets_col_name])

# convert the list of strings into a list of sets for better performance (order is not important)
subsets_list = [set(ast.literal_eval(i)) for i in subsets_str]

# print the number of minimal subsets of competencies found in the task-competency matrix
print('Number of unique minimal subsets found in the matrix: {}'.format(len(subsets_list)))

###########################################
# COMPUTE THE BASE OF THE COMPETENCE SPACE
###########################################

"""
Not all the subsets in the list of minimal subset of competencies are states of the base.
The subsets are part of the base if they cannot be obtained by the union of two or more subsets in the base.
"""

not_base = []

# copy the list of minimal subsets to a new one which will be iteratively updated
subsets_updated = subsets_list.copy()

# iterate over the subsets in the list of minimal subsets
for idx, state_for_base in enumerate(subsets_list):
    skip = 0
    
    base_state_len_constant = len(state_for_base)
    base_state_len = len(state_for_base)
    
    # only by uniting sets which are subsets of state x, the result can be x 
    subsets_to_combine = [i for i in subsets_updated if i.issubset(state_for_base) and len(i) != len(state_for_base)]
    
    # perform all types of combinations (if subset has 4 items, we want combinations 2 by 2 and 3 by 3)
    while base_state_len > 1 and skip == 0: 
        
        # iterate over the list of possible combinations
        for comb in itertools.combinations(subsets_to_combine, base_state_len):
            # perform the union of all items in comb
            subset = set().union(*list(comb))
            
            # if state_for_base = subset then state_for_base is not part of the base
            # also, it cannot be used to generate other subsets as it is not part of the base
            if state_for_base == subset:
                not_base.append(state_for_base)
                subsets_updated.remove(state_for_base)
                skip = 1
                break
                
        base_state_len-=1

# create function to calculate the difference between two lists
def Diff(li1, li2):
    li_dif = [i for i in li1 + li2 if i not in li1 or i not in li2]
    return li_dif

# compute the base of the competence space
base = Diff(subsets_list, not_base)
print('{} sets were removed because they are not part of the base of the competence structure (they can be generated by the union of states in the base.\nThe base of the competence space has {} states.'.format(len(subsets_list)-len(base), len(base)))

# save the base in an excel file
output_path = r'path\file_name.xlsx'
pd.Series(base).to_excel(output_path)  

#####################################################
# GET THE TASKS ASSOCIATED TO EACH STATE IN THE BASE
#####################################################

"""
Each set of tasks that can be solved with the set of competencies in a base state,
is a state of the performance structure.
"""

performance_base = []
for state in base:
    indexes = [index for index, subset in enumerate(all_minimal_subsets) if subset == state]
    tasks_solvable = "{"+str(([tasks[index] for index in indexes]))[1:-1].replace("'", "")+"}"
    performance_base.append(tasks_solvable)

# get base with the items in each base state ordered
ordered_base = []
for i in base:
    state = list(i)
    state.sort()
    ordered_base.append("{"+str(state)[1:-1]+"}")

# create dataframe with the base of the competence space and associated performance states
bases = pd.DataFrame(performance_base, columns = ["Performance Base states"])
bases.insert(0, 'Competence Base States', ordered_base)

# save the base states and associated performance states in excel file
output_path = r'path\file_name.xlsx'
bases.to_excel(output_path)  


##################################
# GET THE NODES TO DRAW THE GRAPH
##################################

"""
The information on the nodes of the structure can be given to Gephi through a csv file.
The csv file must contain the node/state ID and in our case, it will contain the node label,
which is the state composition.
"""

base_state_ids_df = pd.DataFrame(columns = ['Id', 'Label'])
# the ID is sequential 
base_state_ids_df.Id = range(1,126,1)

labels = []
# sort the inside lists from lowest to highest value (for visualization purposes)
for i in base:
    base_list = list(i)
    base_list.sort()
    labels.append(base_list)

base_state_ids_df.Label = [str(i).replace(",", ";").replace("[","{").replace("]","}") for i in labels]

# save the nodes file to be imported to Gephi
output_path = r"path\gephy_nodes.csv"
base_state_ids_df.to_csv(output_path, index=False)


##################################
# GET THE EDGES TO DRAW THE GRAPH
##################################
"""
The information on the relations between the nodes (the edges) of the structure can be given to Gephi through
a csv file.
The csv file must contain the source state ID and the target state ID.
"""

# get dictionary with the state ID as key and the state composition as value
base_state_ids = dict(zip(range(1,126,1), base))

# create dataframe to store the edges/relations
source_target = pd.DataFrame(columns= ['SourceStateID', 'SourceState', 'TargetStateID', 'TargetState'])

""" 
Iterate through the states in the base to get the existing source/target relationships between base states.
For each state x in the base, if state x is a subset of state y, then there is a relation where x is the source
state and y is the target state. These relations will be stored in the dataframe source_target.
"""
for state_id1, state_base1 in base_state_ids.items():
    for state_id2, state_base2 in base_state_ids.items():
        if state_base1.issubset(state_base2) and state_base1 != state_base2:
            new_row = {'SourceStateID':state_id1, 'SourceState':state_base1, 'TargetStateID':state_id2, 'TargetState':state_base2}
            source_target = source_target.append(new_row, ignore_index=True) 

# save the source_target dataframe into a csv for exploration purposes
output_path = r"path\all_edges.csv"
source_target.to_csv(output_path, index=False)

"""
In the code above, the states which were subsets of others were determined.
The code below is intended to drop unnecessary relations that can be inferred from others.
If a chain of precedencies is found, only the consecutive precedencies are maintained 
(e.g. state {1} is a subset of the states {1, 11} and {1, 11, 13}, but {1, 11} is also a subset of {1, 11, 13},
consequently, only the edges ({1}, {1, 11}) and ({1, 11}, {1, 11, 13}) are kept as edges)
"""

# get a list of the states which are the source state in at least one relation
DistinctSourceIDs = source_target.SourceStateID.value_counts().index.to_list()
DistinctSourceIDs.sort()

# first, save the edges as a list of sets [(sourceID, stateID), (sourceID, stateID), ...]
list_source_target = []
for index, row in source_target.iterrows():
    list_source_target.append((row['SourceStateID'], row['TargetStateID']))

# list to store the sets/relations to be dropped
list_to_drop = []

# find the relations to drop
for SourceID in DistinctSourceIDs:
    sourceID_df = source_target.loc[source_target['SourceStateID'] == SourceID]
    target_states = list(source_target.loc[source_target['SourceStateID'] == SourceID]['TargetStateID'])
    
    for idx1, target1 in enumerate(target_states):
        for idx2, target2 in enumerate(target_states):
            
            if idx1 != idx2 and (target1, target2) in list_source_target:
                
                if [SourceID, target2] not in list_to_drop:
                    list_to_drop.append([SourceID, target2])

# drop from source_target the relations stored in list_to_drop
for index, row in source_target.iterrows():
    if [row.SourceStateID, row.TargetStateID] in list_to_drop:
        source_target.drop(index, inplace=True)

# add column "Type" to dataframe. This column will tell Gephi that the edges have a direction
source_target["Type"] = 'Directed'

# change the name of the columns in the dataframe to correspond to what Gehi expects
source_target = source_target.rename(columns={"SourceStateID": "Source", "TargetStateID": "Target"})

# save the final edges to a csv file to be imported in Gephi
output_path = r"path\gephy_edges.csv"
source_target[['Source','Target','Type']].to_csv(output_path, index=False)



