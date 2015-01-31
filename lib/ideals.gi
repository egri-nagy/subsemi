################################################################################
##
## SubSemi
##
## Distributing subsemigroup enumeration along the ideal structure
##
## Copyright (C) 2013  Attila Egri-Nagy
##

#actually building the Rees factor semigroup as the right regular representation
#of the quotient by ideal I
InstallGlobalFunction(ReesFactorHomomorphism,
function(I)
  local quotienthom,regrepisom; 
  quotienthom:=HomomorphismQuotientSemigroup(ReesCongruenceOfSemigroupIdeal(I));
  regrepisom:=IsomorphismTransformationSemigroup(Range(quotienthom));
  return CompositionMapping(regrepisom, quotienthom);
end);

InstallGlobalFunction(RFHNonZeroPreImages,
function (l,rfh)
  local result,t,preimgs;
  result := [];
  for t in l do
    preimgs := PreImages(rfh,t);
    if Size(preimgs) = 1 then
      Add(result, preimgs[1]);
    fi;
  od;
  return result;
end);

InstallMethod(SubSgpsByIdeals,"for a semigroup ideal",[IsSemigroupIdeal],
function(I)
  local mtS,mtI,mtT,mtSminusI, rfh,T,Tsubs,Isubs, emptyset,subs,realsubs,torsos;
  mtS := MulTab(Parent(I));
  emptyset := BlistList(Indices(mtS),[]);
  mtI := MulTab(I);
  #recoding the subsemigroups of ideal as subsgps of the original
  Isubs := List(AsList(SubSgpsByMinExtensions(mtI)),
              x->ReCodeIndicatorSet(x,SortedElements(mtI),SortedElements(mtS)));
  
  rfh := ReesFactorHomomorphism(I);
  T := Range(rfh); #T=S\I
  mtT := MulTab(T);
  subs := AsList(SubSgpsByMinExtensions(mtT));
  realsubs := List(subs, x->SetByIndicatorFunction(x,SortedElements(mtT)));
  torsos := Set(realsubs, x->RFHNonZeroPreImages(x,rfh));
  Tsubs := List(torsos, x->IndicatorFunction(x,SortedElements(mtS)));
  
  Add(Isubs,emptyset);
  Add(Tsubs,emptyset);
  #taking the subsgps generated by the unions
  return Combiner(Tsubs, Isubs, mtS);
end);

# two sets plainly
InstallGlobalFunction(Combiner,
function(A,B,mt)
  local result, a,b;
  result := HeavyBlistContainer();
  for a in A do
    for b in B do
      AddSet(result, SgpInMulTab(UnionBlist(a,b),mt));
    od;
  od;
  return AsList(result);
end);

# A bigger, B potentially inside
InstallGlobalFunction(ConjugacyClassCombiner,
function(A,B,mt)        
  local Cas, Ca, Cbs,result;
  result := [];
  Cas := List(A,x->ConjugacyClassOfSet(x,mt));#precalculate a's conjugacy classes
  Cbs := List(B,x->ConjugacyClassOfSet(x,mt));#precalculate B's conjugacy classes
  for Ca in Cas do
    Append(result, AsList(CombineConjugacyClassWithClasses(Ca,Cbs,mt)));
  od;
  return result;
end);

#calculates all distinct pairwise unions of sets in A and sets in B
Unions := function(A,B,mt)
  return Set(EnumeratorOfCartesianProduct(A,B),UnionBlist);
end;

InstallGlobalFunction(CombineConjugacyClassWithClasses,
function(Ca,Cbs,mt)
  local hashtab,Cb,combined;
  hashtab := HeavyBlistContainer();
  #for each union collecting its representative
  for Cb in Cbs do
    Perform(Unions(Ca,Cb,mt),
            function(x) AddSet(hashtab,ConjugacyClassRep(x,mt));end);
  od;
  Info(SubSemiInfoClass,1,Concatenation(String(Size(hashtab))," unionreps"));
  #collect what they generate
  combined := AsList(hashtab);
  hashtab := HeavyBlistContainer();
  Perform(combined, function(x) AddSet(hashtab, SgpInMulTab(x,mt));end);
  Info(SubSemiInfoClass,1,Concatenation(String(Size(hashtab))," sgps"));
  #sgps may be in the same conjugacy class, so making them unique
  combined := AsList(hashtab);
  hashtab := HeavyBlistContainer();
  Perform(combined, function(x) AddSet(hashtab, ConjugacyClassRep(x,mt));end);
  return hashtab;
end);

# upper torso conjugacy reps, expressed as elements of S
# I an ideal in S (S is contained as a parent)
# G the automorphism group of S
UpperTorsos := function(I,G)
local rfh,T,mtT,Treps,preimgs,elts,tmp,mtS;  
  #get the Rees quotient as ts
  rfh := ReesFactorHomomorphism(I);
  T := Range(rfh);
  #calculate its subsgp classes
  mtT := MulTab(T,G,rfh);
  Treps := AsList(SubSgpsByMinExtensions(mtT));
  #mapping back the subs of the quotient to the original
  preimgs := List(SortedElements(mtT),x->PreImages(rfh,x));
  #from preimageset to elements, getting rid of zero by failing it
  elts := List(preimgs,function(x) if Size(x)> 1 then return fail;
                                   else return x[1];fi;end);
  tmp := List(Treps, x->SetByIndicatorFunction(x,elts));
  Perform(tmp, function(x) if fail in x then
      Remove(x, Position(x,fail));fi;end);
  mtS := MulTab(Parent(I),G); 
  return  List(Unique(tmp),x-> IndicatorFunction(x,mtS));
end;

# calculates all sub conjugacy reps of S/I then extends all upper torsos
# I semigroup ideal
# G automorphism group
# calcideal flag if true, then the empty uppertorso is used
SubSgpsByUpperTorsos := function(I,G,uppertorsos)
  local extended, filter, result, S,mtS;
  S := Parent(I);
  mtS := MulTab(S,G); 
  extended := List(uppertorsos, x-> SgpInMulTab(x,mtS));
  filter := IndicatorFunction(AsList(I),SortedElements(mtS));
  result := [];
  Perform(extended, function(x)
    Append(result,AsList(
            SubSgpsByMinExtensionsParametrized(mtS,x,filter,Stack(),[])));end);
  return result; #TODO duplicates when the ideal has only one element
end;

InstallOtherMethod(SubSgpsByIdeals,"for an ideal and an automorphism group",
        [IsSemigroupIdeal,IsPermGroup],
function(I,G)
  return SubSgpsByUpperTorsos(I,G,UpperTorsos(I,G));
end);
