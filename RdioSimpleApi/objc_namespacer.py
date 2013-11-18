#namespacer for objc
#(c) Francesco "redsh" Rossi 2013

import os,sys,json,subprocess


out = subprocess.check_output(['grep', '-rn', '@inte'+'rface', '.'])

prefix = 'RD_'
print('//Paste the following to your prefix.h')

lines = out.split('\n')
for l in lines:
	print l

for l in lines:
	l = l.split('@inte'+'rface ')
	if len(l)>1:
		l = l[1].split(' ')[0]
		
		print('#define %s %s'%(l,prefix+l))


