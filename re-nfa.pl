% Progetto prolog "Compilatore NFA" A.A. 2014 / 2015
% Cognome: Manfredelli
% Nome: Mauro
% Matricola: 781266
% ------------------------------------------------
% definizione dei predicati dinamici:

:- dynamic initial/2.
:- dynamic final/2.
:- dynamic delta/4.
:- dynamic loop/4.

% is_regexp/1 :
% Vero se RE è un' espressione regolare.

is_regexp(RE) :-
	% controllo per ogni espressione regolare.
	RE \= [],
	is_regexp_ok(RE).

% is_regexp_ok/1 :
% predicato ausiliare dell' is_regexp/1, controlla i
% diversi casi
% per cui un'espressione regolare è corretta.

is_regexp_ok(RE) :-
	% un atomo è espressione regolare.
	atomic(RE),
	!.

is_regexp_ok(RE) :-
	% serve per verificare in che caso mi trovo
	functor(RE, seq, _),
	!,
	% trasformo la funzionein una lista
	RE =.. [seq | Xs],
	% e controllo (a meno del nome della funzione)
	% se tutti gli elementi sono espressioni reg.
	is_regexp_list(Xs).


is_regexp_ok(RE) :-
	% lo star ha solo un argomento.
	functor(RE, star, 1),
	!,
	% controllo lavalidità dell'argomento.
	arg(1, RE, X),
	is_regexp(X).

is_regexp_ok(RE) :-
	% deve avere un solo argomento.
	functor(RE, plus, 1),
	!,
	arg(1, RE, X),
	is_regexp(X).

is_regexp_ok(RE) :-
	% come star e plus: stesso ragionamento.
	functor(RE, bar, 1),
	!,
	arg(1, RE, X),
	is_regexp(X).

is_regexp_ok(RE) :-
	% come seq.
	functor(RE, alt, _),
	!,
	RE =.. [alt | Xs],
	is_regexp_list(Xs).

is_regexp_ok(RE) :-
	% la vedo come la alt semplificata.
	functor(RE, oneof, _),
	!,
	RE =.. [oneof | Xs],
	% non ho una lista di espressioni regolari
	% ma di atomi.
	is_atomic_list(Xs).

% is_regexp_list/1 :
% Vero se tutti gli elementi della lista sono espressioni
% regolari.
% Essendo liste generate con univ da delle funzioni,
% sicuramente conterranno almeno un elemento
% (le funzioni non possono avere arietà 0) quindi
% sicuramente non userò solo il caso base.
is_regexp_list([X]) :-
	is_regexp(X),
	!.
is_regexp_list([X | Xs]) :-
	is_regexp(X),
	!,
	is_regexp_list(Xs).

% is_atomic_list/1 :
% Vero se la lista è formata solo da atomi, usata nel controllo
% dell' espressione regolare con oneof.
is_atomic_list([X]) :-
	atomic(X),
	!.
is_atomic_list([X | Xs]) :-
	atomic(X),
	!,
	is_atomic_list(Xs).

% nfa_compile_regexp/2 :
% predicato che mi genera l'automa NFA;
% FA_Id : identificatore dell'automa,
% RE : espressione regolare che lo genera.
% Vero se l'NFA è generato correttamente.
nfa_compile_regexp(FA_Id, RE) :-
	% non posso avere due identificatori uguali.
	not(initial(FA_Id, _)),
	% FA_Id non può essere una variabile.
	nonvar(FA_Id),
	% RE deve essere un'espressione regolare.
	is_regexp(RE),
	% univ utile per il riconoscimento del
	% procedimento da usare.
	RE =.. List,
	% genero stato iniziale e finale per questo automa
	% e li inserisco nella mia base di conoscenza.
	gensym(q, Qi),
	gensym(q, Qf),
	assert(initial(FA_Id, Qi)),
	assert(final(FA_Id, Qf)),
	% verifico che espressione regolare ho e procedo.
	nfa_compile_regexp_case(FA_Id, List, Qi, Qf).

% nfa_compile_regexp/4 :
% verifico in che caso sono per genere gli stati con le giuste
% associazioni
% FA_Id: solito identificatore,
% [X | Xs]: lista generata precedentemente con univ,
% Qi: stato iniziale,
% Qf: stato finale.
% Uso la testa della lista per verificare in che caso mi trovo.
nfa_compile_regexp_case(FA_Id, [X | []], Qi, Qf) :-
	!,
	compile_atomic(FA_Id, X, Qi, Qf).

nfa_compile_regexp_case(FA_Id, [seq | Xs], Qi, Qf) :-
	!,
	compile_seq(FA_Id, Xs, Qi, Qf).

nfa_compile_regexp_case(FA_Id, [star | Xs], Qi, Qf) :-
	!,
	compile_star(FA_Id, Xs, Qi, Qf).

nfa_compile_regexp_case(FA_Id, [plus | Xs], Qi, Qf) :-
	!,
	compile_plus(FA_Id, Xs, Qi, Qf).

nfa_compile_regexp_case(FA_Id, [alt | Xs], Qi, Qf) :-
	!,
	compile_alt(FA_Id, Xs, Qi, Qf).

nfa_compile_regexp_case(FA_Id, [oneof | Xs], Qi, Qf) :-
	!,
	compile_oneof(FA_Id, Xs, Qi, Qf).

% compile_atomic/4 :
% FA_Id : identificatore,
% X : atomo singolo (quando uso questopredicato sono sicuro che
%     X non sia una lista),
% Qi : stato di partenza,
% Qf : stato di arrivo.
% Non necessariamente sono iniziale e finale, questo
% predicato lo uso anche per la generazione di altre RE
% più complesse.
compile_atomic(FA_Id, X, Qi, Qf) :-
	% inserisco la transizione.
	assert(delta(FA_Id, Qi, X, Qf)).

% compile_seq/4 :
% FA_Id : identificatore,
% [X | Xs] o [X] (a seconda se caso base o meno): lista delle
%     espressioni regolari da concatenre,ù
% Qi : stato di partenza,
% Qf : stato di arrivo.
%
% Passo base:
compile_seq(FA_Id, [X] ,Qi, Qf):-
	!,
	% X è un'espressione regolare e dunque la compilo
	% come tale.
	X =.. K,
	% a seconda del tipo cambio il procedimento.
	nfa_compile_regexp_case(FA_Id, K, Qi, Qf).
% Passi successivi:
compile_seq(FA_Id, [X | Xs], Qi, Qf) :-
	gensym(q, Qint),
	% Per il singolo elemento uso il caso base con
	% lo stato intermedio.
	compile_seq(FA_Id, [X], Qi, Qint),
	% chiamo ricorsivamente sulla coda.
	compile_seq(FA_Id, Xs, Qint, Qf).

% compile_star/4:
% FA_Id: identificatore,
% [X]: lo star agisce su un singolo argomento dunque
%      la lista contiene solo una RE,
% Qi: stato di partenza,
% Qf: stato di arrivo.
compile_star(FA_Id, [X], Qi, Qf) :-
        % genero la lista.
	X =.. K,
	% genero gli stati iniziali e finali dell'automa
	% interno.
	gensym(q, Qi2),
	gensym(q, Qf2),
	% compilo l'espressione regolare interna.
	nfa_compile_regexp_case(FA_Id, K, Qi2, Qf2),
	% lo star accetta la stringa vuota (epsilon) quindi
	% posso passare direttamente dall'inizio alla fine
	% senza leggere niente.
	assert(delta(FA_Id, Qi, epsilon, Qf)),
	% posso andare dallo stato iniziale a quello dell'
	% automa interno.
	assert(delta(FA_Id, Qi, epsilon, Qi2)),
	% una volta che sono in Qf2 posso:
	% ripetere
	assert(delta(FA_Id, Qf2, epsilon, Qi2)),
	% andare nello stato finale.
	assert(delta(FA_Id, Qf2, epsilon, Qf)).

% compile_plus/4:
% Il funzionamento è analogo alla compile_star/4 salvo per una
% differenza ----> la stringa vuota non è più  accettata.
% Lo vedo come la seq(X, star(X)).
compile_plus(FA_Id, [X], Qi, Qf) :-
     nfa_compile_regexp_case(FA_Id, [seq, X, star(X)], Qi, Qf).

% compile_alt/4 :
% Il comportamento è analogo a quello della compile_seq/4,
% l'unica differenza è che vengono generati degli stati
% iniziali
% e finali di appoggio per crearci sopra gli automi
% per le espressioni regolari più interne.
%
% Passo base:
compile_alt(FA_Id, [X], Qi, Qf) :-
	!,
	X =.. K,
	gensym(q, Qi2),
	gensym(q, Qf2),
	assert(delta(FA_Id, Qi, epsilon, Qi2)),
	assert(delta(FA_Id, Qf2, epsilon, Qf)),
	nfa_compile_regexp_case(FA_Id, K, Qi2, Qf2).
% Passo successivo:
compile_alt(FA_Id, [X | Xs], Qi, Qf) :-
	% per l'elemento singolo uso il caso base.
	compile_alt(FA_Id, [X], Qi, Qf),
	% chiamata ricorsiva.
	compile_alt(FA_Id, Xs, Qi, Qf).

% compile_oneof/4 :
% Come la compile_alt semplificata, ossia la lista che gli
% passo sono scuro sia fatta solo di atomi e non anche da
% funtori.
% Il controllo che la lista sia solo di atomi lo faccio nella
% is_regexp nel caso in cui riconosco il termine oneof.
% Ho due passi.
% Passo base:
compile_oneof(FA_Id, [X], Qi, Qf) :-
	!,
	assert(delta(FA_Id, Qi, X, Qf)).
% Passi successivi:
compile_oneof(FA_Id, [X | Xs], Qi, Qf) :-
	!,
	assert(delta(FA_Id, Qi, X, Qf)),
	compile_oneof(FA_Id, Xs, Qi, Qf).

% nfa_recognize/2 :
% FA_Id : identificatore dell'automa che uso per la recognize,
% Input : stringa da accettare.
% Vero se la stringda è accettata.
nfa_recognize(FA_Id, Input) :-
	nonvar(FA_Id),
	nonvar(Input),
        % prendo lo stato iniziale di questo NFA.
	initial(FA_Id, Q),
	% inizio il riconoscimento partendo dallo stato
	% iniziale.
	% cancello la memoria per il loop.
	clear_loop(FA_Id),
	nfa_recognize(FA_Id, Input, Q).
% I primi due sono semplici:
% Se non mi è rimasto nulla da leggere e sono in uno stato
% finale allora la parola è accettata.
nfa_recognize(FA_Id, [], Q) :-
	final(FA_Id, Q),
	!.
% Se è presente una delta che mi permettere di leggere
% un carattere della stringa allora mi sposto e continuo
% il riconoscimento.
nfa_recognize(FA_Id, [I | Input], Q) :-
	delta(FA_Id, Q, I, P),
	nfa_recognize(FA_Id, Input, P).

% Questi due riguardano casi con epsilon-mosse:
% utilizzo il predicato loop per evitare che il
% controllo vado in stallo in un certo pezzo dell'automa.
nfa_recognize(FA_Id, Input, Q) :-
	delta(FA_Id, Q, epsilon, P),
	% se non ho ancora effettuato questa epsilon
	% mossa la salvo nella mia memoria loop.
	not(loop(FA_Id, Q, P, _)),
	assert(loop( FA_Id, Q, P, 1)),
	nfa_recognize(FA_Id, Input, P).

nfa_recognize(FA_Id, Input, Q) :-
	delta(FA_Id, Q, epsilon, P),
	% se ho già effettuato questa epsilon-mossa
	loop(FA_Id, Q, P, T),
	% verifico se non sono in loop
	T =< 100,
	% se non lo sono aumento il contatore dei
	% passaggi.
	N is T+1,
	% rimuovo il vecchio inserisco il nuovo.
	retract(loop(FA_Id, Q, P, T)),
	assert(loop(FA_Id, Q, P, N)),
	nfa_recognize(FA_Id, Input, P).

% pulisco la memoria di loop:
% rimuovo tutti i fatti loop/4 con FA_Id.
clear_loop(FA_Id) :-
	retractall(loop(FA_Id, _, _, _)).

% predicati di utility :
%
% nfa_clear/0 :
% pulisce la base di conoscenza da tutti i fatti riguardanti
% la generazione di tutti gli NFA.
nfa_clear :-
	nfa_clear_nfa(_).

% nfa_clear_nfa/1 :
% FA_Id : identificatore dell'NFA di cui voglio eliminare i
% fatti di stati e transizioni dell'automa.
nfa_clear_nfa(FA_Id) :-
	retractall(initial(FA_Id, _)),
	retractall(final(FA_Id, _)),
	retractall(delta(FA_Id, _, _, _)).

% nfa_list/0 :
% effettua il listing dei fatti riguardanti ogni automa
% presente nella base di conoscenza.
nfa_list :-
	nfa_list(_).

% nfa_list/1 :
% effettua il listing dei fatti riguardanti
% l'automa identificato dal FA_Id.
nfa_list(FA_Id) :-
	listing(initial(FA_Id, _)),
	listing(final(FA_Id, _)),
	listing(delta(FA_Id, _, _, _)).

% fine del file.

















