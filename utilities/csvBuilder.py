#sending to bonnie+seth 
#ver 1
import csv
import os
import os.path
import re


def clearTagSlow(text):
   levelOfTag = 0
   ans = ""
   for c in text:
      if ( c == "<"):
        levelOfTag = levelOfTag + 1
      elif (c ==">"):
         levelOfTag = levelOfTag - 1
      elif (levelOfTag == 0):
         if(c != "\t"):
            ans = ans + c
   return ans
   
def dividePages(text):
#   listOfPages = re.split('<pb n=\"\d*vr*\"/>', text)
   listOfPages = re.split('<pb n=\"\d', text)
   i=0
   while i < len(listOfPages):
      pos = listOfPages[i].find(">")  +1
      listOfPages[i] = listOfPages[i][pos:]
      listOfPages[i]=re.sub("\s\s+" , " ", listOfPages[i])
      listOfPages[i] = removeSpaceEnd(removeDoubleWS(clearTagSlow(listOfPages[i])))
      i = i + 1
   return listOfPages


def getXMLFiles(name):
   f = open(name, 'r')
   text = f.read()
   listOfPages =  dividePages(text)
   return listOfPages

def removeSpaceEnd(words):
   while words.endswith(" "):
      words = words[:len(words)-2]
   return words
 
def removeDoubleWS(words):
   return re.sub("\s\s+" , " ", words)


def buildItem( transLA,transEN, item):
   #get the Name for a csv and put it into a list of list
   
   #csvFileName = raw_input("what is the name of the file you would like to open?")
   print("you are about to build an item")
   pathToFolder = raw_input("what is relative path to to FOLDER that  ")
   namesOfFiles = os.listdir("./"+str(pathToFolder))
   for i in namesOfFiles:
      if (i.endswith("jpg")) == False:
         print("removing fileNamed "+i)
         namesOfFiles.remove(i)
   print(namesOfFiles)
  
   if(  raw_input("are these the file you want to copy? (y/n)  ") != "y"):  
      print("nothing added")   
      return item

   csvFileName = raw_input("what is the name of the CSV FILE you would like to open?(include RELATIVE path)    ")
   fin = open(csvFileName, 'r')
   inter = csv.reader(fin)
   csvData = []
   for row in inter:
      csvData.append(row)


   #quick tag check, if there are any issues exit()
   testData = ['title', 'description', 'type', 'format', 'location:placename', 'date:start', 'date:end', 'language', 'provenance', 'subject', 'datecreated:start', 'datecreated:end', 'originalsource:text', 'originalsource:url', 'customtext:copyright', 'customtext:permission', 'customtext:license', 'customlink:licenseurl:text']
   i = 0
   while i < len(csvData[0]):
      if(csvData[0][i] != testData[i]):
         print ("Wrong first row, Stopping")
         print ("["+str(csvData[0][i]) + "] is not the same as [" + str(testData[i])+"]" )
         exit()
      i = i + 1

   #build and add the the itemRow
   itemRow = []
   itemId= "d" + raw_input("What is the item ID Number?")
   itemRow.append(itemId)        #0 itemId
   itemRow.append("")            #1 subitemid
   itemRow.append("")            #2 orderId
   itemRow.append(csvData[1][0]) #3 title
   itemRow.append(csvData[1][1]) #4 description
   itemRow.append("sequence")    #5 fileType
   
   #six rows exist and we need 19 total rows
   j = 0
   while j < 19:
      itemRow.append("")  
      j = j +1 
#   item = []
   item.append(itemRow)
   
    


   subItemNumber = 1
   relPath = pathToFolder
   for fileName in namesOfFiles:
#	LApass = transLA[subItemNumber+1]
#	ENpass = trasnEN[subItemNumber+1]
#        if(subItemNumber -1 > len(transLA)):
	LApass = "NONE?"
#	else:
#		LApass = transLA[subItemNumber - 1]


#	if(subItemNumber -1 > len(transEN)):
	ENpass = "NONE?"
#	else:
#		ENpass = transEN[subItemNumber - 1]
	subitemRow = buildRow(fileName,csvData,subItemNumber,itemId,relPath,LApass,ENpass)
   	item.append(subitemRow)
        subItemNumber +=1

   return item


def buildRow(name,csvData,subItemNumber,itemId,relPath,LA,EN):
   print("         building Row name="+str(name))
   path   ="/"+relPath+name
   tranLA =LA
   tranEN =EN
   partOfName = name.split("-")
   withOutExt = partOfName[2].split(".")
   pageNumber = int(withOutExt[0])
   row = []
   row.append(itemId)                               #0  itemid
   row.append(itemId +"." +str(subItemNumber))      #1  subitemid
   row.append(subItemNumber)                        #2  order
   row.append("Page "+str(pageNumber))              #3  title
   row.append("The "+str(pageNumber/2)+"th folio.") #4  description
   row.append("Image")                              #5  fileType
   row.append(path)                                 #6  filespec
   row.append(csvData[1][2])                        #7  type
   row.append(csvData[1][3])                        #8  format
   row.append(csvData[1][4])                        #9  location
   row.append(csvData[1][5])                        #10 startDate
   row.append(csvData[1][6])                        #11 endDate
   row.append(csvData[1][7])                        #12 la
   row.append(csvData[1][8])                        #13 procenance
   row.append(csvData[1][9])                        #14 subject
   row.append(tranLA)                               #15 TranScription Latin
   row.append(tranEN)                               #15 TranScription English
   row.append(csvData[1][10])                       #16 createdDateStart
   row.append(csvData[1][11])                       #17 createdDateEnd
   row.append(csvData[1][12])                       #18 originalSourceText
   row.append(csvData[1][13])                       #19 originalSourceURL
   row.append(csvData[1][14])                       #20 CopyRight
   row.append(csvData[1][15])                       #21 CustomText
   row.append(csvData[1][16])                       #22 CustomLicense
   row.append(csvData[1][17])                       #23 LicenseURL?

   return row

def buildHeader():
   header = [["itemid","subitemid","orderid","title","description","filetype","filespec","type","format","location:placename","date:start","date:end","language","provenance","subject","transcript/la","transcript/en","datecreated:start","datecreated:end","originalsource:text","originalsource:url","customtext:copyright","customtext:permission","customtext:license","customlink:licenseurl:text"]]
   return header


def writeDataOut(finishedCSV):
   outFileName = raw_input("what would you like to name the output file?") 
   if outFileName == "":
      outFileName = "default.csv"
   with open(outFileName, 'wb') as csvfile:
      writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
      for f in finishedCSV:
         writer.writerow(f)


#main
#LA = getXMLFiles("./"+(raw_input("Where is the LATIN XML file   " )))
#EN = getXMLFiles("./"+(raw_input("Where is the ENGLISH XML FILE?   ")))
LA = []
EN =[]
data = buildHeader()
while 'y' == (raw_input("do you want to add a new item?(y/n)     "  )) :
	data = buildItem(LA,EN,data)

writeDataOut(data)
#x=getXMLFiles("./transXMLPage/data.xml")
#for y in x:
#	print y
#	print "---------------"

