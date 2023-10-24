Integer numRows = 0;
Integer numCols = 0;

// Get the required row and column length
for(Integer i=0,imax=mdArray.size(); i<imax; i++){
	if(numCols < imax){numCols = imax;}
	for(Integer j=0,jmax=mdArray[i].size(); j<jmax; j++){
		if(numRows < jmax){numRows = jmax;}
	}
}

// Pad the table with null values
for(Integer i=0; i<numRows; i++){
	output.add(new Object[]{});
	for(Integer j=0; j<numCols; j++){
		output[i].add(null);
	}
}

// Invert the array
for(Integer i=0,imax=mdArray.size(); i<imax; i++){
	for(Integer j=0,jmax=mdArray[i].size(); j<jmax; j++){
		output[j][i] = mdArray[i][j];
	}
}