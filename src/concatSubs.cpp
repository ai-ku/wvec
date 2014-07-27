#include <math.h>
#include <iostream>
#include <stdio.h>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
using namespace std;
map <string,vector<float> >targetD;
map <string,vector<float> >contextD;
int tSize,cSize;
int readEmbed(map< string,vector<float> >& dict,char *filename)
{
  ifstream femb(filename);
  string token,line,vval;

  vector<float>v;
  while(getline( femb, line ))
    {
      istringstream lstream(line);
      lstream >> token;

      v.clear();
      while(lstream >> vval)
	{
	  v.push_back(atof(vval.c_str()));
	}
      dict[token] = v;
    }

  int D=dict[token].size();
  if(dict.find("*UNKNOWN*") == dict.end())
    {
      vector<float>unkv(D);
      int i,j=0;
      cerr << "embeddings do not have UNK tag word " << endl;
      cerr << D << "dimension UNK tag word will be created " << endl;

      for(map< string,vector<float> >::iterator it=dict.begin();it!=dict.end();++it,++j)
	{
	  i = 0;
	  for(vector<float>::iterator it2= dict[(*it).first].begin();it2!=dict[(*it).first].end();++it2,++i)
	      unkv[i] += (*it2);

	}
      for(i=0;i<D;i++)
	unkv[i] = unkv[i]/j;
      string utoken = "*UNKNOWN*";
      dict[utoken] = unkv;
      cerr << endl <<"DONE!" << endl;
    }
  return dict[token].size();
}
void debugE(map< string,vector<float> >& dict)
{
  for(map< string,vector<float> >::iterator it=dict.begin();it!=dict.end();++it)
    {
      cout << (*it).first;
      for(vector<float>::iterator it2= dict[(*it).first].begin();it2!=dict[(*it).first].end();++it2)
	{
	  cout << (*it2) << " " ;
	}
      cout << endl;
    }

}

int main(int argc, char **argv)
{
      if (argc<2) {
       printf("Usage: zcat TARGET_CORPUS.sub.gz | ./concatSubs <target embeddings FILE> <context embeddings FILE>  > TARGET_CORPUS.target+context");
	return 0;
    }
    tSize = readEmbed(targetD,argv[1]);
    cSize = readEmbed(contextD,argv[2]);

    string line;
    float logp,p,sum;
    string targettoken,ttoken,token,ctoken,vval;
    int N;
    while(getline(cin, line ))
       {
	istringstream lstream(line);
     	vector<float>subs;
     	vector<string>tokens;

     	lstream >> targettoken;
	if(targettoken.compare("</s>")==0)
	  continue;

     	sum = 0;
     	while(lstream >> token)
     	  {
     	    tokens.push_back(token);
     	    lstream >> vval;

     	    logp = atof(vval.c_str());
     	    //p = pow(10.0,logp);
	    p = exp(logp);
     	    sum += p;
     	    subs.push_back(p);
     	  }

     	N=subs.size();
     	for(int i=0;i<N;i++)
     	    subs[i] = subs[i]/sum;

     	if(targetD.find(targettoken) == targetD.end())
	  ttoken="*UNKNOWN*";
	else
	  ttoken=targettoken;

     	vector<float>cVec(cSize,0.0);

     	for(int i=0;i<N;i++)
     	  {
     	    ctoken = tokens[i];
     	    if(contextD.find(ctoken) == contextD.end())
     	      ctoken="*UNKNOWN*";

	    for(int j=0;j<cSize;++j)
	      cVec[j] += subs[i]*contextD[ctoken][j];
    	   }
	cout << targettoken << " ";
	for(int i=0;i<tSize;i++)
	  cout << targetD[ttoken][i] << "\t";
     	for(int i=0;i<cSize;i++)
	  cout << cVec[i] << "\t";
	cout << endl;
       }
}
