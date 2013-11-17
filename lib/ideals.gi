################################################################################
##
## SubSemi
##
## Distributing subsemigroup enumeration along the ideal structure
##
## Copyright (C) 2013  Attila Egri-Nagy
##

#actually building the Rees factor semigroup
InstallGlobalFunction(ReesFactorHomomorphism,
function(I)
  local cong,quotienthom,regrepisom; 
  cong := ReesCongruenceOfSemigroupIdeal(I);
  quotienthom := HomomorphismQuotientSemigroup(cong);
  regrepisom := IsomorphismTransformationSemigroup(Range(quotienthom));
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

InstallGlobalFunction(SubSgpsByIdeals,
function(S,I)
  local mtS,mtI,mtT,mtSminusI, rfh,T,Tsubs,Isubs, emptyset,subs,realsubs,torsos;
  mtS := MulTab(S);
  emptyset := BlistList(Indices(mtS),[]);
  mtI := MulTab(I);
  #recoding the subsemigroups of ideal as subsgps of the original
  Isubs := List(AsList(SubSgpsBy1Extensions(mtI)),
              x->ReCodeIndicatorSet(x,SortedElements(mtI),SortedElements(mtS)));
  
  rfh := ReesFactorHomomorphism(I);
  T := Range(rfh); #T=S\I
  mtT := MulTab(T);
  subs := AsList(SubSgpsBy1Extensions(mtT));
  realsubs := List(subs, x->ElementsByIndicatorSet(x,SortedElements(mtT)));
  torsos := Unique(List(realsubs, x->RFHNonZeroPreImages(x,rfh)));
  Tsubs := List(torsos, x->IndicatorSetOfElements(x,SortedElements(mtS)));
  
  Add(Isubs,emptyset);
  Add(Tsubs,emptyset);
  #taking the subsgps generated by the unions
  return Combiner(Tsubs, Isubs, mtS);
end);

# two sets plainly
InstallGlobalFunction(Combiner,
function(A,B,mt)
  local result, a,b;
  result := [];#DynamicIndexedHashSet([SizeBlist,FirstEntryPosOr1]);
  for a in A do
    for b in B do
      AddSet(result, SgpInMulTab(UnionBlist(a,b),mt));
    od;
  od;
  return result;
end);

# A bigger, B potentially inside
InstallGlobalFunction(ConjugacyClassCombiner,
function(A,B,mt)
  local hashtab,a,Ca,Cb,Cbs,combined;
  hashtab := DynamicIndexedHashSet([SizeBlist,FirstEntryPosOr1,LastEntryPosOr1]);
  Cbs := List(B,x->ConjugacyClassOfSet(x,mt));#precalculate B's conjugacy classes
  for a in A do
    Ca := ConjugacyClassOfSet(a,mt);
    for Cb in Cbs do
      Perform(List(EnumeratorOfCartesianProduct(Ca,Cb),UnionBlist),
              function(x)AddSet(hashtab,x);end);
    od;
  od;
  Info(SubSemiInfoClass,1,Concatenation(String(Size(hashtab))," unions"));
  combined := AsList(hashtab);
  hashtab := DynamicIndexedHashSet([SizeBlist,FirstEntryPosOr1,LastEntryPosOr1]);
  Perform(combined, function(x)AddSet(hashtab, SgpInMulTab(x,mt));end);
  Info(SubSemiInfoClass,1,Concatenation(String(Size(hashtab))," sgps"));
  combined := AsList(hashtab);
  hashtab := DynamicIndexedHashSet([SizeBlist,FirstEntryPosOr1,LastEntryPosOr1]);
  Perform(combined, function(x)AddSet(hashtab, ConjugacyClassRep(x,mt));end);
  return hashtab;
end);
