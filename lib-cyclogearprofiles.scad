/*
###########################################################
required: OpenSCAD version >= 2015.03
title: cyclogearprofiles
description: a minimal library to generate cycloidical gears
date: 2015-04-17
author: (C) mechadense aka Lukas M. Süss
license: Dual licensed either CC-BY-SA or LGPL v3.0
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>
###########################################################
*/

// rolling radius - trivial but use it to make code more self explanatory
function rollingradius(rtooth,nteeth) = 2*nteeth*rtooth;

// helper functions for herringbone gears
function tootharclength(r,n) = 2*3.141592653*rollingradius(r,n)/n;
function extrudeheight1tooth(r,n,slantangle) = tootharclength(r,n)*tan(slantangle);
function twitsangle1tooth(n) = 360/n;

module twistextrudegear(rtooth,nteeth,slant=45,nteethtwist=1)
{
    noverlap = nteethtwist; // number off teeth to turn over
    slantangle = slant; // 90° means straight teeth (keep >30° to limit overhangs)
    h = extrudeheight1tooth(rtooth,nteeth,slantangle);// tootharclength*tan(slant); 
    linear_extrude(height=h*noverlap,twist=(360/nteeth)*noverlap,convexity=8) children();
}

// _1 ... gear in origin; _2 ... meshed gear
// beta12 ... angle at which the meshed gear is located
// nX ... number of teeth of gear X; alphaX ... rotation angle of gear X
  function alpha2(n1,n2,alpha1,beta12) = 180 -alpha1/n2*n1 +beta12*(1+n1/n2);
// for greas rolling inside concave gears
  function alpha2inroll(n1,n2,alpha1,beta12) = 0 +alpha1/n2*n1 +beta12*(1-n1/n2);


// values for teethshift0 are {-0.75,-0.5,0,+0.5,+0.75} all others have same effect
module cyclorackprofile(trackmin=10,rtooth=4,nteeth=5,teethshift0=0,vpt=0)
{
  circunit = 2*3.141592653; // unit circle circumference

  teethshift00 = floor(teethshift0*4)/4;
  function sphi(phi) = phi + teethshift00*2*circunit; // shift the starting phase
  function cyclo(r2,phi) = [(-r2+r2*cos(-sphi(phi)/circunit*360))*
                                      sign(sin((sphi(phi)/2)/circunit*360+0)),
                            r2*phi+r2*sin(-sphi(phi)/circunit*360)];
  // make sure the number of quater-teeth-groove pairs is a positive natural number
  // otherwise the rack length is nontrivial to calculate
  n = max(floor(nteeth*4),1)/4;
  lrack = 2*circunit*rtooth*n; // 2 full rolls once inside once outside

  // may not work - needs more testing
  usedvpt = vpt>0 ? vpt : ( ($fn>0) ? $fn :
            ceil((360/$fa)/(2*n))
            );

  npoints = n*usedvpt; // number of points for the whole rack

  list1ToN   = [ for (i = [0 : npoints]) i ];
  pointlist = [ for (i = list1ToN) cyclo(rtooth,2*n*circunit/npoints*i) ];
  looppoints = [[+rtooth+trackmin,lrack],[+rtooth+trackmin,0]];

  list1ToN2  = concat(list1ToN,[npoints+1,npoints+2]);
  pointlist2 = concat(pointlist,looppoints);

  polygon(points = pointlist2, paths = [list1ToN2],convexity = 6);
}

module cyclogearprofile(rtooth=4,nteeth=5,vpt=0,verbouse=0)
{
  // functions for generation of hypo- and epicycloids
  //asserted: r1 > r2 (& divisible without remainder)!! <<<<<<< TODO check for that
  function hypo_cyclo(r1,r2,phi) = 
   [(r1-r2)*cos(phi)+r2*cos(r1/r2*phi-phi),(r1-r2)*sin(phi)+r2*sin(-(r1/r2*phi-phi))];
  function epi_cyclo(r1,r2,phi) = 
   [(r1+r2)*cos(phi)-r2*cos(r1/r2*phi+phi),(r1+r2)*sin(phi)-r2*sin(r1/r2*phi+phi)]; 
  // alternating hypo- and epicycloids
  function epihypo(r1,r2,phi) = 
    pow(-1, 1+floor( (phi/360*(r1/r2)) )) <0 ? epi_cyclo(r1,r2,phi) : hypo_cyclo(r1,r2,phi);

  // make sure the number of teeth-groove pairs is a positive natural number
  n = max(floor(nteeth),1);

  rrollcircle = rtooth*(2*n);
  // vpt ... vertices per tooth
  usedvpt = vpt>0 ? vpt : ( ($fn>0) ? $fn :
            ceil(min( (360/$fa)/(2*n) , (2*rrollcircle*3.141592653/$fs)/(2*n) ))
            ); 
  npoints = n*usedvpt;

  if(verbouse>0)
  {
    echo("the gear with ID: ",verbouse);
    echo(rtooth=rtooth,nteeth=nteeth);
    echo("the gears rolling radius is: ", rrollcircle);
    if(vpt==0) echo("used for the resolution: ",$fa=$fa,$fs=$fs,$fn=$fn);
    echo("this gear has a resolution of ",usedvpt, " verices per tooth");
    echo("this makes ",npoints, " verices in total");
  }

  list1ToN  = [ for (i = [0 : npoints]) i ];
  pointlist = [ for (i = list1ToN) epihypo(rrollcircle,rtooth,360/npoints*i) ];
  polygon(points = pointlist, paths = [list1ToN],convexity = 6);
}
