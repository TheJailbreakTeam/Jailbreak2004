class JBCamera extends Keypoint;


// TODO: implement properly


function ActivateFor(Controller Controller) {

  if (PlayerController(Controller) != None)
    PlayerController(Controller).SetViewTarget(Self);
  }


defaultproperties {

  bNoDelete = True;
  bStatic = False;
  }