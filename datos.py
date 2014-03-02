#!/usr/bin/env python3

import csv

dataset = csv.reader(open('Oldenburg.csv', 'r'),delimiter='\t')
output = csv.writer(open('Prueba1.csv', 'w', newline=''), delimiter='\t')

next(dataset)
for id, time, latitude, longitude in dataset:
	if(time == '0'):
		output.writerow([id, time, latitude, longitude])
