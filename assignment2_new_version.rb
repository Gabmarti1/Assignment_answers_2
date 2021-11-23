require 'rest-client'
require 'json'
# we require the file in which we have creted the networkss and classes
require './Interaction_networks_assignment2.rb'
#here  the gene file will be the first attribute that we are going to give in the command line
filename = ARGV[0]
report = ARGV[1]
#here we run all the script(functions)
Networks.get_url_of_genes(filename)
Networks.get_gene_related(0.485)
dict =Networks.interactors
dict1 = Networks.interactors_indirect
Networks.annotate_keggs_go(dict)
Networks.annotate_keggs_go(dict1)

#report
File.open(report,'w+') do |line|
    line.puts ("Report,Interactions Networks Between coexpressed genes\n")
    line.puts ("This report contains direct and indirect networks between the genes present in the file\n")
    line.puts ("Direct networks only contain two genes of the text while an indirect network has one gene not present in the file which connect the others gene in the file\n ")
    line.puts ("Networks also contain informatioon about kegg and go terms,id\n")
    line.puts ("Have been detected#{Networks.num} ")
    n = 0
    Networks.array_of_objects.each do |objects|
        n += 1
        line.puts("Network:#{n}\n")
        line.puts("members:#{objects.members}\n")
        line.puts("kegg_terms:#{objects.kegg_path}\n")
        line.puts("go_terms:#{objects.go_terms}\n")
        
    end
end