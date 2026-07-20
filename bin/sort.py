import pandas as pd

# Load both files
data = pd.read_csv('top1000.association.tsv.case.variants.tsv', sep='\t')
order = pd.read_csv('association.tsv', sep='\t')

unique_order = order['gene'].drop_duplicates()

data['Gene.refGene'] = pd.Categorical(data['Gene.refGene'], categories=unique_order, ordered=True)
data_sorted = data.sort_values('Gene.refGene', na_position='last')

data_sorted.to_csv('top1000-sorted.association.tsv.case.variants.tsv', sep='\t', index=False)
