require 'sinatra'
require 'json'
require 'google/cloud/storage'


storage = Google::Cloud::Storage.new(project_id: 'cs291a')
bucket = storage.bucket 'cs291project2', skip_lookup: true

get '/' do
  #"Hello World\n"
  redirect to('/files/')
end

get '/files/' do
files = bucket.files
arrayFile = []
files.each do |file|
  #puts file.name.downcase
  puts "Given "+file.name
  if file.name[2]!='/'
	puts "bad 1 "+file.name
        next
  end
  if file.name[5]!='/'
	puts "bad 2 "+ file.name
	next
  end
  #if file.name.count('/')>2||file.name.count('/')<2||file.name[2]!='/'||file.name[5]!=['/']
  n = file.name.tr('/','')
  l = n.length
  if l<64||l>64||(n.match?(/^[[:xdigit:]]+$/))!=true||((n =~ /[A-Z]/)!=nil)
	puts "bad 3 "+n
	next
  end
  arrayFile.push(file.name.downcase)
end
sorted = arrayFile.sort
finalArray = []
sorted.each do |a|
    name = a.tr('/','')
    finalArray.push(name)
end
content_type :json
status(200)
"#{finalArray}"
end

post '/files/' do
  files = bucket.files
  if params[:file]==nil||params[:file]==""||params[:file]=="file"||params[:file]=="tempfile"
     return status(422)
  end
  puts params[:file]
  fileObj = params[:file][:tempfile]
  file_path = params[:file][:tempfile].path
  #file_name = params[:file][:filename]
  puts File.size(fileObj)
  puts params[:file][:type]
  if File.size(fileObj)>(1024*1024)
	return status(422)
  end
  sha256 = Digest::SHA256.file fileObj
  digestIs=sha256.hexdigest
  fileName=sha256.hexdigest
  puts digestIs
  content_type(params[:file][:type])
  headers "Content-Type" => params[:file][:type]
  digestIs=digestIs.downcase
  files.each do |file|
  	n = file.name.tr('/','')
	n = n.downcase
	if n==digestIs
		return status(409)
	end
  end
   #fileName=digestIs
   puts fileName
   fileName=fileName.downcase
   fileName.insert(2,'/')
   fileName.insert(5,'/')
   puts digestIs
   puts fileName
  # Upload file to Google Cloud Storage bucket
  bucket.create_file file_path, fileName, content_type: params[:file][:type]
status(201)
body('created')
#files.each do |file|
        #puts file.name
  	#puts file.content_type
 # end
{"uploaded": "#{digestIs}" }.to_json
#"uploaded: #{digestIs}\n"
end

get '/files/:digest' do
 files = bucket.files
 puts params[:digest]
 fileReq= params[:digest]
 fileReq=fileReq.downcase
 #filetype=params[:digest][:type]
 puts fileReq
 l=fileReq.length
 if l<64||l>64||(fileReq.match?(/^[[:xdigit:]]+$/))!=true
  return status(422)
 end
 flag=-1
  files.each do |file|
  	n = file.name.tr('/','')
	n = n.downcase
  	if n==fileReq
            flag=0
            ct=file.content_type
 	    content_type(ct)
  	end
  
   end
 if flag==-1
 	return status(404)
 end
#content_type(filetype)
 attachment(filename = fileReq)
 fileReq.insert(2,'/')
 fileReq.insert(5,'/')
 puts fileReq
 file = bucket.file fileReq
 #puts file.path
 file.download "temp" 
 f = File.open("temp")
 s = f.read
 puts s
# file.read
 body(s)
 return status(200) 
end

delete '/files/:digest' do
    files = bucket.files
    fileReq= params[:digest]
    l=fileReq.length
    puts l
    if l<64||l>64||(fileReq.match?(/^[[:xdigit:]]+$/))!=true
        return status(422)
    end
    fileReq=fileReq.downcase
    files.each do |file|
  	n = file.name.tr('/','')
	n = n.downcase
	#puts file.name
	#puts "\n----------\n"
	#puts fileReq
  	if n==fileReq
 		file = bucket.file file.name
		file.delete
  	end
  
    end
return status(200)   
end


post '/' do
  require 'pp'
  PP.pp request
  "POST\n"
end

