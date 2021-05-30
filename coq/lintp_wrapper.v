From Coq Require Import Reals.
From Coquelicot Require Import Coquelicot.

Require Import Lra Lia.
Require Import List Permutation.
Require Import Morphisms EquivDec Program.
Require Import Classical_Prop.
Require Import Classical.

Require Import Utils.
Require Import NumberIso.
Require Export SimpleExpectation.
Require Import AlmostEqual.
Require Import Event.
Require Import SigmaAlgebras.
Require Import ProbSpace.
Require Import BorelSigmaAlgebra.
Require Import LInt_p.sigma_algebra.
Require Import LInt_p.measure.
Require Import LInt_p.measurable_fun.
Require Import LInt_p.LInt_p.
Require Import LInt_p.sigma_algebra_R_Rbar.
Require Import LInt_p.sum_Rbar_nonneg.
Require Import Classical.

Set Bullet Behavior "Strict Subproofs".

Import ListNotations.

Definition lintp_borel_sa : SigmaAlgebra R := generated_sa gen_R_uc.

Program Instance measurable_sigma_algebra {T} (F:pre_event T -> Prop) : SigmaAlgebra T
  := { sa_sigma := measurable F }.
Next Obligation.
  now apply measurable_union_countable.
Qed.
Next Obligation.
  apply measurable_compl.
  unfold pre_event_complement.
  apply measurable_ext with (A).
  intro x; tauto.
  apply H.
Qed.
Next Obligation.
  apply measurable_compl.
  unfold pre_Ω.
  apply measurable_ext with (fun _ => False).
  tauto.
  apply measurable_empty.
Qed.

Theorem measurable_sa {T} (F:pre_event T -> Prop) : 
  forall a, prob_space_closure F a <-> measurable F a.
Proof.
  split; intros.
  - induction H.
    + unfold pre_Ω.
      apply measurable_compl.
      apply measurable_ext with (fun _ => False).
      tauto.
      apply measurable_empty.
    + now apply measurable_gen.
    + now apply measurable_union_countable.
    + apply measurable_compl.
      unfold pre_event_complement.
      apply measurable_ext with (q).
      intro; tauto.
      trivial.
  - induction H.
    + now apply psc_refl. 
    + assert (@pre_event_equiv T (fun _ => False) (pre_event_complement (fun _ => True))).
      {
        intro x.
        unfold pre_event_complement.
        tauto.
      }
      rewrite H.
      apply psc_complement.
      apply psc_all.
    + assert (@pre_event_equiv T A (pre_event_complement (fun x => ~ A x))).
      {
        intro x.
        unfold pre_event_complement.
        tauto.
      }
      rewrite H0.
      now apply psc_complement.
    + now apply psc_countable.
Qed.

Definition dec_pre_event {Ts} (dom : SigmaAlgebra Ts) ( A : pre_event Ts) :
  {sa_sigma A} + {~ sa_sigma A}.
Proof.
  apply ClassicalDescription.excluded_middle_informative.
Qed.

Program Definition ps_P_pre {Ts} {dom : SigmaAlgebra Ts} (prts : ProbSpace dom) :
  (pre_event Ts -> R) :=
  fun (A : pre_event Ts) =>
    if (dec_pre_event dom A) then ps_P A else 0.

Lemma disjoint_pre_collection {T} (coll : nat -> pre_event T) :
  pre_collection_is_pairwise_disjoint coll <->
  (forall n m x, coll n x -> coll m x -> n = m).
Proof.
  unfold pre_collection_is_pairwise_disjoint.
  unfold pre_event_disjoint.
  split; intros.
  - specialize (H n m).
    assert ((n <> m) -> False).
    + intros.
      now specialize (H H2 x H0 H1).
    + tauto.
  - specialize (H n1 n2 x H1 H2).
    lia.
Qed.

Lemma measurable_pre_event {Ts} (dom : SigmaAlgebra Ts) (E : pre_event Ts) :
  measurable sa_sigma E <-> sa_sigma E.
Proof.
  split; intros.
  - induction H; trivial.
    + apply sa_none.
    + apply sa_complement in IHmeasurable.
      assert (pre_event_equiv (pre_event_complement (fun x : Ts => ~ A x))
                              A).
      * intro x.
        unfold pre_event_complement.
        tauto.
      * now rewrite H0 in IHmeasurable.
    + admit.
  - now apply measurable_gen.
Admitted.

(* need to create a (measure gen) from probspace. *)
Program Definition ProbSpace_measure {Ts} {dom : SigmaAlgebra Ts} (prts : ProbSpace dom) : measure (@sa_sigma Ts dom) := mk_measure _ (ps_P_pre prts) _ _ _  .
Next Obligation.
  unfold ps_P_pre, ps_P_pre_obligation_1.
  match_destr.
  assert (event_equiv
            (exist (fun e : pre_event Ts => sa_sigma e) (fun _ : Ts => False) s)
            event_none) by 
      (intro x; simpl; tauto).
  rewrite H.
  now rewrite ps_none.
Qed.
Next Obligation.
  unfold ps_P_pre.
  match_destr.
  apply ps_pos.
  lra.
Qed.
Next Obligation.
  unfold ps_P_pre, ps_P_pre_obligation_1.
  apply disjoint_pre_collection in H0.
  
  match_destr.
  - admit.
  - 
Admitted.
  
  Definition Rbar_Expectation_posRV {Ts} {dom : SigmaAlgebra Ts} (prts : ProbSpace dom) (f : Ts -> Rbar) := 
    LInt_p (ProbSpace_measure prts) f.

  Class Rbar_PositiveRandomVariable {Ts}
          (rv_X:Ts->Rbar) : Prop :=
    prv : forall (x:Ts), (Rbar_le 0 (rv_X x)).

  Lemma Rbar_pos_nonneg {Ts} (f : Ts -> Rbar) 
        (prv : Rbar_PositiveRandomVariable f) :
    non_neg f.
  Proof.
    unfold Rbar_PositiveRandomVariable in prv.
    unfold non_neg.
    apply prv.
  Qed.

  Lemma measurable_fun_sa_sigma {Ts} {dom : SigmaAlgebra Ts} (f : Ts -> Rbar)
        {rv : RandomVariable dom Rbar_borel_sa f} :
     measurable_fun_Rbar sa_sigma f.
  Proof.
    unfold measurable_fun_Rbar.
    unfold measurable_fun.
    intros.
    unfold RandomVariable in rv.
    rewrite <- Rbar_borel_sa_preimage2 in rv.
    unfold gen_Rbar, gen_Rbar_cu in H.
    induction H.
    - destruct H.
      apply measurable_gen.
      assert (pre_event_equiv (fun x0 : Ts => A (f x0))
                              (fun x0 => Rbar_ge (f x0) x)) by (intro z; apply H).
      rewrite H0.
      now apply Rbar_sa_le_ge.
    - apply measurable_empty.
    - now apply measurable_compl.
    - now apply measurable_union_countable.
  Qed.

  Lemma Rbar_Expectation_posRV_plus {Ts} {dom : SigmaAlgebra Ts} (prts : ProbSpace dom) (f g : Ts -> Rbar) 
    {prv1 : Rbar_PositiveRandomVariable f}
    {prv2 : Rbar_PositiveRandomVariable g} 
    {rv1 : RandomVariable dom Rbar_borel_sa f}
    {rv2 : RandomVariable dom Rbar_borel_sa g}    :
    inhabited Ts ->
    Rbar_Expectation_posRV prts (fun x => Rbar_plus (f x) (g x)) = 
    Rbar_plus (Rbar_Expectation_posRV prts f) (Rbar_Expectation_posRV prts g).
  Proof.
    intros.
    unfold Rbar_Expectation_posRV.
    apply LInt_p_plus; trivial.
    now apply measurable_fun_sa_sigma.
    now apply measurable_fun_sa_sigma.    
  Qed.
    



  
                                         


