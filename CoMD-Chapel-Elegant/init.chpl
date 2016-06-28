use configs;
use setup;
use types;
use helpers;
use force;
use forcelj;
use forceeam;

// Global force
const locDom  : domain(3) = {0..xproc-1, 0..yproc-1, 0..zproc-1};
var globalForce : Force;
var targetLocales : [locDom] locale;
var Sim: Simulation(targetLocales.type);

proc defineForce() {
  tArray[timerEnum.FCREATE].start();
    if(doeam) {
      globalForce = new ForceEAM(potDir, potName, potType);
    }
    else {
      globalForce = new ForceLJ();
    }
  tArray[timerEnum.FCREATE].stop();
}


proc defineSpace(latticeConstant) {
  // local copies of global configs

  simLow  = (0.0,0.0,0.0);
  const simSize = (nx:real, ny:real, nz:real) * latticeConstant;
  simHigh = simSize;

  const minSimSize = 2*globalForce.cutoff;
  assert(simSize(1) >= minSimSize && simSize(2) >= minSimSize && simSize(3) >= minSimSize);
  assert(globalForce.latticeType == "FCC" || globalForce.latticeType == "fcc");

  for i in 1..3 do numBoxes(i) = (simSize(i)/globalForce.cutoff) : int;

  boxSize = simSize / numBoxes;


  const boxSpace = {1..numBoxes(1), 1..numBoxes(2), 1..numBoxes(3)};
  return boxSpace;
}


proc defineTargetLocales() {
  const targetLocales : [locDom] locale;
  var count: int(32) = 0;
  for l in targetLocales {
    l = Locales(count);
    count = count + 1;
  }
  return targetLocales;
}


/*
  Global namespace
*/
class Simulation {
  var targetLocales;
  var Space : domain(3);
  var DistSpace = Space dmapped Block(boundingBox=Space, targetLocales=targetLocales);
  var f  : [DistSpace] [1..MAXATOMS] real3;     // force per atom in local cells
  var pe : [DistSpace] [1..MAXATOMS] real;      // potential energy per atom in local cells
  var vSim  : Validate;
}

