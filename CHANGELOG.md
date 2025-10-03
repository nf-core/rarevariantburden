# nf-core/rarevariantburden: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - [10/03/2025]

Initial release of nf-core/rarevariantburden, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Split the case joint called and VQSR applied VCF files chromosomewise
- Normalize and QC the splitted case VCF files
- Annotate normalized and QCed VCF files with Annovar and VEP
- Convert the normalized and annotated VCF files to GDS format, which is easier to process in R (Using R seqarray)
- Predict the ethnicity of the case samples (Using gnomAD random forest classifier)
- Perform association test for each VCF file using our CoCoRV (Consistent summary Count based Rare Variant burden test) R package, if sex is provided, do the association analysis with sex-stratification
- Calculate false positive rate (FDR) from merged results, plot QQ plot and lambda value using different R libraries
- For top K genes, generate the list of samples and associated variants along with the annotations for the variants, this list will help the users to further check the top genes and their variants
