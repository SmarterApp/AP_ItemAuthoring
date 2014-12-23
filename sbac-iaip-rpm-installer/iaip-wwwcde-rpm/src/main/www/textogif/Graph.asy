import graph;
import math;

defaultpen(Helvetica("m","n")+fontsize(18.0));

pen axispen = Helvetica("m","n")+fontsize(12.0);
pen titlepen = Helvetica("m","n")+fontsize(12.0);
pen drawpen = Helvetica("m","n")+fontsize(15.0);

// Input parameters

int[] omitx = {};
int[] omity = {};

int width = 270;
size(width,0);

string title = "";

int xmin = 0;
int xmax = 10;
int xstep = 1;
string xtitle = "\boldmath$x$";
bool xticks = true;

int ymin = 0;
int ymax = 10;
int ystep = 1;
string ytitle = "\boldmath$y$";
bool yticks = true;

bool showgrid = true;
bool skiplabels = false;
bool labelorigin = false;
bool dashedline = false;
bool shadeabove = false;
bool shadebelow = false;
bool axistitles = false;


if(dashedline) {
  drawpen = drawpen+dashed;
}

if(shadeabove) {
  if(1 == xmin && 2.5 == ymax) {
	  fill((1,1)--(xmin,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == xmin && 5 == xmax) {
    fill((1,1)--(xmin,ymax)--(xmax,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymin && 5 == xmax) {
	  fill((1,1)--(xmin,ymin)--(xmin,ymax)--(xmax,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymin && 2.5 == ymax) {
	  fill((1,1)--(xmin,ymin)--(xmin,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == xmin && 2.5 == ymin) {
	  fill((1,1)--(xmin,ymax)--(xmax,ymax)--(xmax,ymin)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymax && 5 == xmax) {
	  fill((1,1)--(xmax,ymax)--(5,2.5)--cycle,lightgray);
  }
		
	if(1 == ymax && 2.5 == ymin) {
	  fill((1,1)--(xmax,ymax)--(xmax,ymin)--(1,1)--cycle,lightgray);
	}	
}

if(shadebelow) {
  if(1 == xmin && 2.5 == ymax) {
	  fill((1,1)--(xmin,ymin)--(xmax,ymin)--(xmax,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == xmin && 5 == xmax) {
    fill((1,1)--(xmin,ymin)--(xmax,ymin)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymin && 5 == xmax) {
	  fill((1,1)--(xmax,ymin)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymin && 2.5 == ymax) {
	  fill((1,1)--(xmax,ymin)--(xmax,ymax)--(5,2.5)--cycle,lightgray);
	}

	if(1 == xmin && 2.5 == ymin) {
	  fill((1,1)--(xmin,ymin)--(5,2.5)--cycle,lightgray);
	}

	if(1 == ymax && 5 == xmax) {
	  fill((1,1)--(xmin,ymax)--(xmin,ymin)--(xmax,ymin)--(5,2.5)--cycle,lightgray);
  }
		
	if(1 == ymax && 2.5 == ymin) {
	  fill((1,1)--(xmin,ymax)--(xmin,ymin)--(1,1)--cycle,lightgray);
	}	
}  

real slope = (2.5 - 1)/(5 - 1);
real intercept = 2.5 - slope * 5;

// Draw grid if showgrid == true

if(showgrid) {
   add(shift(xmin,ymin)*grid((int)xmax - (int)xmin,(int)ymax - (int)ymin,linewidth(0.5)));
}

bool contains (int[] iarray, int i) {

  for(int j=0; j < iarray.length; ++j) {
    if(iarray[j] == i) { return true; }
  }

  return false;
}

if(title != "") {
  label(title,((xmax+xmin)/2,1.25 * ymax),titlepen+black);
}

// draw x/y axis

if(xticks == true) {
  path xp1 = (0,0)--(xmax+1,0);
  draw(xp1,currentpen+1.5bp,EndArrow(9.0));
	label(xtitle,(xmax+1,0),E);
  //draw(xtitle,xp1,length(xp1),drawpen,currentpen+1.5bp,EndArrow(9.0));

  if(labelorigin) { label((string)0,(0,0),SW,axispen); }

  for(int i=1; i <= xmax; ++i) {
    if(skiplabels && abs(i) % 2 == 1) { continue; }

    if(contains(omitx,i) == false) {
      fill(shift((i - 0.25,-0.70))* scale(0.60) * unitsquare, white);
      label((string)(i * xstep),(i,0),S,axispen);
    }    
  }

  if(xmin < 0) {
    path xp2 = (0,0)--(xmin-1,0);
    draw(xp2,currentpen+1.5bp,EndArrow(9.0));

    for(int i=xmin; i <= -1; ++i) {
      if(skiplabels && abs(i) % 2 == 1) { continue; }
     
      if(contains(omitx,i) == false) {
        fill(shift((i - 0.25,-0.70))* scale(0.60) * unitsquare, white);

        label((string)(i * xstep),(i,0),S,axispen);
      }
    }

  }

} else {
  xaxis(xtitle,xmin,xmax+1);
}

if(yticks == true) {
  path yp = (0,0)--(0,ymax+1);
  draw(yp,currentpen+1.5bp,EndArrow(9.0));
	label(ytitle,(0,ymax+1),N);

  for(int i=1; i <= ymax; ++i) {
    if(skiplabels && abs(i) % 2 == 1) { continue; }

    if(contains(omity,i) == false) {
      fill(shift((-0.70,i-0.25))* scale(0.60) * unitsquare, white);
      label((string)(i * ystep),(0,i),W,axispen);
    }
  }

  if(ymin < 0) {
    path yp2 = (0,0)--(0,ymin-1);
    draw(yp2,currentpen+1.5bp,EndArrow(9.0));

    for(int i=ymin; i <= -1; ++i) {
      if(skiplabels && abs(i) % 2 == 1) { continue; }

      if(contains(omity,i) == false) {
        fill(shift((-0.70,i-0.25))* scale(0.60) * unitsquare, white);
        label((string)(i * ystep),(0,i),W,axispen);
      }
    }
  }

} else {
  yaxis(ytitle,ymin,ymax+1);
}

draw((1,1)--(5,2.5),drawpen+1.5bp,(false && false ? Arrows(9.0) : (false && !false ? BeginArrow(9.0) : (false ? EndArrow(9.0) : None) ) ));

if(true) {
  fill((1,1),scale(1.2mm)*unitcircle,black);  
}

if(true) {
  fill((5,2.5),scale(1.2mm)*unitcircle,black);  
}

if(axistitles) {
  label("\textbf{x}",(xmax/2,-1.5),titlepen+black);
	label("\textbf{y}",90,(-1.5,ymax/2),titlepen+black);
}
shipout();