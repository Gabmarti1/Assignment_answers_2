#we call the following modules in order to search in databases and be able to manage the results of the web page
require 'rest-client'
require 'json'
#we create  the class networks
class Networks
    #we create a variable to count the nomber of networks
    @@num = 0
    #we stablish the attributes of the objects
    attr_accessor :geneid
    attr_accessor :members
    attr_accessor :go_terms
    attr_accessor :kegg_path
    #we create the hashes in which we will save the interactors of the genes in the list
    @@interactors_direct = Hash.new
    @@interactors_indirect = Hash.new
    
    @@all_objects = []
   
    def initialize (params={})
        #wee initalize the attributes
        @geneid = params.fetch(:geneid,'')
        @members = params.fetch(:members,[])
        @kegg_path = params.fetch(:kegg_list,[])
        @go_terms = params.fetch(:go_list,[])
        @@num += 1
        #we add to the list each object
        @@all_objects << self
    end
    #the followinf functions is just to be able to call this variables in the main file
    def self.num
        
        return @@num
    end
    def self.array_of_objects
        return @@all_objects
    end
        def self.interactors
        
        return @@interactors_direct
    end
    def self.interactors_indirect
        
        return @@interactors_indirect
    end
    #we create a list of genes from the file. We go through a list and adding each line(gene) to the list
    def self.get_url_of_genes(filename)
        @@genes = []
        File.foreach(filename) do |line|
            
            @@genes.append(line.strip.downcase)
            
        end
        
    end
    #we create a function to get the result from a search in a web page
    def self.web_access(url,headers = {accept: "*/*"}, user = "",pass= "")
        response = RestClient::Request.execute({
            method: :get,
            url: url.to_s,
            user: user,
            password: pass,
            headers: headers})
        body = response.body   
        return body
            
        rescue RestClient::ExceptionWithResponse => e
            $stderr.puts e.inspect
            response = false
            return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
        rescue RestClient::Exception => e
            $stderr.puts e.inspect
            response = false
            return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
        rescue Exception => e
            $stderr.puts e.inspect
            response = false
            return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    end
    #This function is in order to obtain the interacton networks
    def self.get_gene_related(threshold)
        #we go through the list of genes
        @@genes.each do |gene|
            #we call the function web access to access the information of interactors
            retrieve=Networks.web_access("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{gene}/?format=tab25")
            # we test if the response of the function is correct
            if retrieve
                #we do this beacuse maybe there are multiples interactors of the gene that we are looking for
                retrieve = retrieve.split("\n")
                retrieve.each do |record|
                    #here we select the fields that we are intersted in, first we split by columns
                    record= record.split("\t")
                    gene1 = record[2].sub(/tair:/,"")# we use the sub method to get only the id
                    gene2 = record[3].sub(/tair:/,"")
                    score = record[14].sub(/intact-miscore:/,"").to_f#we are removing the part of the score that is not a value.
                    #if the score is lower than a threshold that we establish 
                    next if score < threshold
                    #here we are filtering by species
                    next if record[9] != "taxid:3702" || record[10] != "taxid:3702"
                    #this line is because we don´t know if teh interactor is in the field 2 or 3
                    if gene1.downcase == gene.downcase && gene2.downcase != gene.downcase
                        interactor = gene2.downcase
                        
                    elsif gene2.downcase == gene.downcase && gene1.downcase != gene
                        interactor = gene1.downcase
                    end     
                    #if the interactor is in the list we have the direct networks
                    if @@genes.include?(interactor)
                        @@interactors_direct[gene] = [gene,interactor]#here we are creting the hash of the direct interactions
                     #if the interactor is not in the file we look for a new interactor
                    else retrieve2 = Networks.web_access("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{interactor}/?format=tab25")
                        #here we do the same as above but here we loof for interactors for the gene wich interact with our gene list
                        if retrieve2
                            
                            retrieve2 = retrieve2.split("\n")
                            retrieve2.each do |record2|
                                record2= record2.split("\t")
                                gene1B = record2[2].sub(/tair:/,"")
                                gene2B = record2[3].sub(/tair:/,"")
                                score2 = record2[14]
                                score2 = score2.sub(/intact-miscore:/,"").to_f
                                next if score2 < threshold
                                next if record2[9] != "taxid:3702" || record2[10] != "taxid:3702"
                                #this line is because we don´t know if teh interactor is in the field 2 or 3
                                if gene1B.downcase == interactor.downcase and gene2B.downcase != interactor.downcase
                                    interactor2 = gene2.downcase
                                    
                                elsif gene2B.downcase == interactor.downcase and gene1B.downcase != interactor.downcase
                                    interactor2 = gene1.downcase
                                    
                                end   
                                #if the gene c is the same as a, this is not a network so we are not going to save it
                                next if interactor2 == gene
                                #here we only take the networks in wich a and c are from the gene list but differents
                                if @@genes.include?(interactor2)
                                    @@interactors_indirect[gene] = [gene,interactor,interactor2]
                                end
                                    
                                
                            end

                        end
                    end

                end
            end
                
            
        end
        
       
        
        
        

    end
    #we defined this function in order to obtain the kegg and ggo terms,id
    def self.annotate_keggs_go(dict)
        annotation_value=[]
        annotation_value2=[]
        #we go through the dictionary either direct or indirect to get the kegg and go terms from the genes in the list and the interactors
        dict.each do |key,values|
            values.each do |value|
                #we call the web_access function to obtain he web information
                terms = Networks.web_access("http://togows.org/entry/kegg-genes/ath:#{value}/pathways.json")
                #we use this method to avoid terms if is empty beacause we can't obtain anything from the url
                next if terms.nil?
                #we call JSON module and parse to manage this information and be ablo to extract what we want.
                term = JSON.parse(terms)#we convert in a list the result
                #we pick the first column where are the keggid and pathway_name
                term[0].each do |kegg_id,pathway_name|
                    annotation_value.append([kegg_id,pathway_name])

                end
                #we do the same but with the web page of go_terms
                terms1 = Networks.web_access("http://togows.org/entry/ebi-uniprot/#{value}/dr.json")
                next if terms1.nil?
                term1 = JSON.parse(terms1)[0]
                for elem in term1["GO"].each
                    #we selecct those with the biological function parameter
                    if elem[1].match(/^P:/)
                        annotation_value2 << [elem[0],elem[1]]#we pick the first and second element of the list, which corresponds with go_id and functional
                    end
                end
            end
            #we create the different objects of the class with the attributes
            Networks.new(:geneid=> key,:members=>values , :kegg_list=>annotation_value , :go_list=>annotation_value2)
        end
    end

   
                

end
