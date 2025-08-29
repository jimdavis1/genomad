# Genomad Service

## Overview

The Genomad service uses the genomad tool (https://github.com/apcamargo/genomad) to identify viral, pro-viral, and plasmid contigs in genomic and metagenomic assemblies. The tool employs a hybrid classification approach that combines an alignment-free neural network with a gene-based classifier that utilizes a  database of over 200,000 marker protein profiles specific to chromosomes, plasmids, and viruses. Genomad also provides taxonomic assignment of viral genomes using ICTV taxonomy.

The app currently does a simple run of genomad, with no additional processing.  In future versions we plan to add viral annotation and our own plasmid classification tools. 


## Inputs and outputs

The input to the servcie is assembled contigs in fasta format.  It will fail with any other file type. 

# Genomad Service Output Files

| File Name | Description |
|-----------|-------------|
| final.contigs_plasmid.fna | FASTA file containing plasmid contigs |
| final.contigs_plasmid_genes.tsv | Tab-separated file with plasmid gene annotations from prokka |
| final.contigs_plasmid_proteins.faa | FASTA file containing plasmid protein sequences |
| final.contigs_plasmid_summary.tsv | Tab-separated summary file for plasmid contigs |
| final.contigs_summary.json | JSON file containing overall summary of all contigs |
| final.contigs_virus.fna | FASTA file containing viral and pro-viral contigs |
| final.contigs_virus_genes.tsv | Tab-separated file with prokka viral gene annotations |
| final.contigs_virus_proteins.faa | FASTA file containing viral protein sequences |
| final.contigs_virus_summary.tsv | Tab-separated summary file for viral contigs |
| geNomad_run.stderr | Standard error log file from the geNomad run |


The output files are greatly reduced compared to all of the output the genomad command line tool produces.  The app pushes these files back into the workspace from a full output directory, so if there is desire to do so, we could add back more of the results files.  

## About this module

This module is a component of the BV-BRC build system. It is designed to fit into the
`dev_container` infrastructure which manages development and production deployment of
the components of the BV-BRC. More documentation is available [here](https://github.com/BV-BRC/dev_container/tree/master/README.md).



| Script name | Purpose |
| ----------- | ------- |
| [App-Genomad.pl](service-scripts/App-Genomad.pl) | App script for the Genomad Service|


## See Also

## References

Identification of mobile genetic elements with genomad Camargo, A.P., Roux, S., Schultz, F., Babinski, M., Xu, Y., Hu, B., Chain, P. S. G., Nayfach, S., & Kyrpides, N. C., - Nature Biotechnology (2023), DOI: 10.1038./s41587-023-01953-y.

https://portal.nersc.gov/genomad/

https://github.com/apcamargo/genomad?tab=readme-ov-file

rnadeepvirome_pt.9440000001_virus.fna


geNomad is a state-of-the-art computational framework that identifies mobile genetic elements—specifically viruses and plasmids—in nucleotide sequencing data from genomes, metagenomes, and metatranscriptomes. The tool employs a hybrid classification approach that combines an alignment-free neural network (using the IGLOO architecture) with a gene-based classifier that utilizes a comprehensive database of over 200,000 marker protein profiles specific to chromosomes, plasmids, and viruses. Beyond classification, geNomad provides taxonomic assignment of viral genomes following ICTV taxonomy, identifies integrated proviruses within host genomes using a conditional random field model, and performs functional annotation of encoded proteins. In benchmarks, geNomad demonstrated superior performance compared to existing tools, achieving Matthews correlation coefficients of 77.8% for plasmids and 95.3% for viruses, while being significantly faster and more scalable—enabling the processing of over 2.7 trillion base pairs of sequencing data to populate the IMG/VR and IMG/PR databases.


