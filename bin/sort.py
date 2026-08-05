#!/usr/bin/env python3
import argparse
import pandas as pd


def main():
    parser = argparse.ArgumentParser(
        description="Sort a variants TSV file by gene order defined in another TSV file."
    )
    parser.add_argument(
        "--data",
        required=True,
        help="Path to the input data TSV file (e.g. top1000.association.tsv.case.variants.tsv)",
    )
    parser.add_argument(
        "--order",
        required=True,
        help="Path to the TSV file defining gene order (e.g. association.tsv)",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to write the sorted output TSV file",
    )
    args = parser.parse_args()

    # Load both files
    data = pd.read_csv(args.data, sep='\t')
    order = pd.read_csv(args.order, sep='\t')

    unique_order = order['gene'].drop_duplicates()

    data['Gene.refGene'] = pd.Categorical(data['Gene.refGene'], categories=unique_order, ordered=True)
    data_sorted = data.sort_values('Gene.refGene', na_position='last')

    data_sorted.to_csv(args.output, sep='\t', index=False)


if __name__ == "__main__":
    main()
