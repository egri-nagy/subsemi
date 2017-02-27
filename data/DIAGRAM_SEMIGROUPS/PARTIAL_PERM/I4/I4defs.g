LoadPackage("subsemi");

# VARIABLES for I4 and its subs
S4 := SymmetricGroup(IsPermGroup,4);
I4 := SymmetricInverseMonoid(4);
I43 := SemigroupIdealByGenerators(I4, [PartialPerm([1,2,3,0])]);
SetName(I43,"I43");
I42 := SemigroupIdealByGenerators(I43,[PartialPerm([1,2,0,0])]);
SetName(I42,"I42");
I41 := SemigroupIdealByGenerators(I42,[PartialPerm([1,0,0,0])]);
SetName(I41,"I41");
mtI4 := MulTab(I4,S4);
mtI43 := MulTab(I43,S4);
mtI42 := MulTab(I42,S4);

################################################################################
# FUNCTIONS for the calculations in enumeration.sh #############################

#1
# subsemigroups of I4 that contain non-trivial permutations
P_I4 := function()
  local subs;
  #we need to filter out the identity as well, simple size check is enough
  subs := SubSgpsByUpperTorsos(I43,
                               S4,
                               Filtered(UpperTorsos(I43,S4),x->SizeBlist(x)>1));
  Add(subs,
      BlistList(Indices(mtI4), [Position(Elts(mtI4),IdentityTransformation)]));
  SaveIndicatorFunctions(subs, Concatenation("P_I4",SUBS@SubSemi));
end;

#2
I42Subs := function()
  local subs;
  subs := SubSgpsByIdeal(I41,S4);
  SaveIndicatorFunctions(List(subs, x-> RecodeIndicatorFunction(x,mtI42,mtI4)),
                         Concatenation("I42",SUBS@SubSemi));
end;

#3
#takes couple of days
I43modI42subs := function()
  SaveIndicatorFunctions(UpperTorsos(I42,S4),
                         Concatenation("I43modI42",SUBS@SubSemi) );
end;

#TODO review
I43SubsOneShot := function()
  local mtI4, mtI43, reps, output, r;
  mtI4 := MulTab(I4,S4);
  mtI43 := MulTab(I43,S4);
  reps := AsList(SubSgpsByMinExtensions(mtI43));
  output := OutputTextFile("I43_I4.reps", false);
  for r in List(reps,
          x->RecodeIndicatorFunction(x,mtI43,mtI4)) do
    AppendTo(output, EncodeBitString(AsBitString(r)),"\n");
  od;
  CloseStream(output);
end;
