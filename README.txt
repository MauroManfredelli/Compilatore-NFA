Progetto prolog "Compilatore NFA" A.A. 2014 / 2015.
Cognome: Manfredelli
Nome: Mauro
Matricola: 781266
_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-

I predicati da utilizzare sono quelli specificati nella consegna:
is_regexp/1, nfa_compile_regexp/2, nfa_recognize/2, i predicati di Utility.

Definisco dei predicati dinamici perchè non sono presenti nella base di 
conoscenza alla consultazione (sono run-time); sono predicati che inserisco
mediante assert durante la compilazione degli NFA. Questi predicati sono: 
initial/2, final/2, delta/4, loop/4. In tutti i casi il primo argomento è L'id
dell'NFA in quanto gli stati e le transizioni cambiano da automa a automa,
mentre il secondo argomento è lo stato dell'automa. Nel caso della delta
ho FA_Id, stato di partenza, simbolo dell'alfabeto che leggo, stato di arrivo.
loop/4 lo spiegherò nella sezione nfa_recognize.

Il primo predicato principale che implemento è is_regexp/1:
questo predicato controlla banalmente se l'espressione regolare non è la 
lista vuota e sucessivamente controlla con un altro predicato se soddisfa
le condizioni di almeno una delle espressioni regolari.
is_regexp_ok/1 { is_regexp_ok(RE) } :
 - se RE è un atomo è VERO;
 - se RE è un funtore con identificatore seq, con un numero di argomenti non
   definito (variabile anonima _ posso andare da 1 in su, 0 da errore),
   creo una lista (con univ) e controllo se gli argomenti 
   della seq sono tutte espressioni regolari escludendo il nome del funtore;
 - se RE è un funtore con identificatore star, con un solo argpomento, 
   controllo se questo argomento è un espressione regolare;
 - se RE è un funtore con identificatore plus, faccio come per lo star;
 - se RE è un funtore con identificatore bar, faccio come per star e plus;
 - se RE è un funtore con identificatore alt, faccio come per la seq e 
   controllo se ho una lista di espressioni regolari;
 - se RE è un funtore con identficatore oneof, con un numero di argomenti non
   definito e la lista che creo è una lista di atomi allora RE è espressione 
   regolare.
 Per ogni is_regexp_ok/2 ho inserito un cut dopo il contollo functor/3 o
 atomic/1 per rendere il programma più efficente.
 Per controllare se una lista contiene espressioni regolari ho usato 
 is_regexp_list/1 con caso base e passo:
 caso base: la lista con un solo elemento è una lista di espressioni regolari 
            se il singolo elemento presente è una espressione reg.
 (essendo la lista generata dalla univ di un funtore sicuramente non
 conterrà zero elementi).
 caso passo: la lista [X | Xs] è unalista di espressioni regolari se X è
             una espressione reg. e lo è anche Xs (chiamata ricorsiva).
  Ho inserito green cuts per determinismo.
  Per controllare se una lista contiene solo atomi uso un predicato analogo:
  is_aomic_list/4 che funziona nello stesso modo della is_regexp_list/4 solo
  che il controllo fatto è atomic(X) invece di is_regexp(X).
________________________________________________________________________________   

CONSIDERAZIONI: 
L'alfabeto di tutti i linguaggi è dato da tutti i possibili atomi che posso 
scrivere in prolog : 
 - lettere del'alfabeto: a, b, c, ....
 - numeri: 1, 2, 3, 4, ....
 - composizione di lettere, numeri, lettere / numeri: abc, 123, a1b2c3, ....
 - è presente un carattere speciale 'epsilon' che non DEVE essere usato come
   caratterre dell'alfabeto, necessario all'implementazione delle transizioni;
   indica il "carattere vuoto".
Le stringhe per il riconoscimento degli automi le indicherò con le parentesi
quadre '[', ']' quindi mediante le liste (il riconoscimento funziona con liste):
 - parola vuota: [] ;
 - [a, b, c], [1, 2, 3], ...
 - ovviamente [a, b, c] \= abc (la prima  è stringa del linguaggio, il secondo
   è carattere dell'alfabeto);
 - [a, b] /= [ab] (la prima è una stringa formata da due caratteri a e b, la 
   seconda è formata da un solo carattere ab).
 Gli schemi NFA che utilizzo contengono spesso epsilon-mosse ossia delle 
 transizioni tra stati che utilizzano la epsilon come carattere letto: questo
 vuol dire che non viene "consumato" nessun carattere della stringa; Sono
 delle mosse interne all'automa usate per considerare tutte i possibili
 percorsi.    
________________________________________________________________________________
 
 Implementazione della nfa_compile_regexp/2 { nfa_compile_regexp(FA_Id, RE) }:
 FA_Id è l'identificatore dell'automa: se nella mia base di conoscenza è già
 presente uno stato iniziale con quell'id allora è gia presente un NFA con
 quel nome e dunque fallisce la compilazione.
 FA_Id non deve essere una variabile altrimenti nel caso contrario mi troverei
 nella base di conoscenza dei fatti con delle variabili anonime come id e non
 mi permetterebbe di implementare altri NFA.
 RE deve essere una espressione regolare (verifico con il predicato 
 is_regexp/1 implementato precedentemente).
 Scrivo RE in una forma a lista per poter verificare di che tipo è l'espressione
 più esterna. Utilizzo la gensym/2 per poter genere gli stati: il nome degli
 stati sarà 'q' seguito da un numero autoincrementato; genero prima solo lo 
 stato iniziale e finale dell'automa e inserisco i fatti relativi nella base
 di conoscenza.
 Uso un predicato diverso per verificare in che caso mi trovo.
 nfa_compile_regexp_case/4 :
 { nfa_compile_regexp_case(FA_Id, List, Qi, Qf) }
 a seconda di cosa ho in testa alla lista decido come compilare l'automa ossia
 come generare gli altri stati e transizioni tra stati.
 Ho implementato un caso per ogni tipo, che compila l'automa a meno del nome del
 funtore. In ogni caso ho inserito un green cut per effettuare determinismo.
 
 Iniziamo dal primo caso: la lista si presenta nella forma [X | []].
 X è sicuramente un atomo (dati i controlli precedenti). Utilizzo dunque
 il predicato compile_atomic/4 (con gli stessi paramentri del case salvo  la 
 lista che è diventata X) che si limita a inserire la delta che dallo stato
 iniziale mi manda nello stato finale leggendo l'atomo X.
 
 Secondo  caso: la lista si presenta nella forma [seq | Xs].
 Utilizzo uno schema simile all' epsilon-NFA: non inserisco le epsilon-mosse
 tra stati intermedi per semplificare l'automa.
 Xs è una lista non vuota di espressioni regolari. Utilizzo il compile_seq/4
 con gli stessi parametri del case a cui passo però solo la coda Xs, che è 
 formato da due casi.
 La lista contiene solo un elemento: collego lo stato iniziale a quello finale
 secondo le regole dell'espressione regolare X; c'è la necessita di chiamare
 nfa_compile_regexp_case/4 che mi crea le giuste transizioni.
 La lista contiene più di un elemento [X | Xs]: genero uno stato intermedio che 
 userò per la generazione delle transizioni di X, e utilizzando il primo caso 
 per compilare la testa, passando come stato finale lo stato intermedio 
 generato. 
 Vado avanti ricorsivamente sulla coda Xs unendo tutte le altre espressioni reg.  
 con lo stato intermedio. Solo nel caso in cui l'elemento è l'ultimo della lista
 uso lo stato finale senza generarne uno intermedio. Avendo due passi ho 
 inserito i cuts.
 
 Terzo caso: la lista si presenta nella forma [star | Xs].
 So che Xs sarà formata da un solo elemento, ma visto che i predicati di 
 compilazione funzionano con liste, preferisco scriverla in questo modo.
 Uso lo schema dell' epsilon_NFA per la star e dunque genero degli stati 
 intermedi raggiungibili con epsilon-mosse (mosse con cui mi sposto nell'NFA
 senza 'consumare' alcun carattere della stringa).
 Gli stati che genero sono lo stato iniziale e finale di appoggio che userò
 per la compilazione dell'espressione reg. interna. Collego gli stati con 
 epsilon-mosse come da commento per poter riconoscere tutte le possibili 
 stringhe.
 
 Quarto caso: la lista si presenta nella forma [plus | Xs].
 Utilizzo la compile_plus/4 implementata in maniera analoga alla 
 compile_star/4. L'unica differenza è che non posso accettre la stringa vuota.
 Essendo molto simile allo star ho deciso di implementarlo come se fosse uno
 star senza la possibilità di riconoscimento della stringa vuota. Vedo dunque
 plus(X) come seq(X, star(X)), in questo modo so che X deve essere letto almeno
 una volta.
 
 Quinto caso: la lista si presenta nella forma [alt | Xs].
 Utilizzo la compile_alt/4, a cui passo la coda Xs.
 Per implementare la alt uso lo schema epsilon-NFA.
 In questo caso ho usato un meccanismo simile a quello della seq a cui ho 
 aggiunto però delle epsilon-mosse:
 La lista è formata da un solo elemento: genero lo stato iniziale e finale
 d'appoggio che collego con quelli dell'alt. Compilo l'espressione regolare
 interna utilizzando gli stati appena generati.
 La lista è formata da più elementi: senza generare alcuno stato intermedio 
 uso il caso precedente per compilare la testa e ricorsivamente compilo anche
 la coda.
 Non è necessario usare stati intermedi in più visto che con l'alt posso 
 scegliere una delle possibili "strade", quindi per tutte le espresioni reg.
 della lista vado dallo stato iniziale a quello finale generando una "strada"
 per ogni elemento della lista.
 Avendo due passi ho inserito i cuts.
 
 Sesto caso: la lista si presenta nella forma [oneof | Xs].
 utilizzo la compile_oneof/4 a cui passo la coda della lista Xs.
 Lavora come un caso particolare della alt:
 Non uso epsilon-mosse per semplificare l'automa. Ho due passi:
 Passo base: ho un solo atomo nella lista dunque aggiungo la transizione da
 inizio a fine con quell'atomo (potevo usare la  compile_atomic ma visto che
 l'istruzione da fare è una sola ho evitato).
 Passo successivo: aggiungo la transizione da inizio a fine leggendo l'atomo 
 in testa e ripeto il procedimento per i restanti. 
 Alla fine avrò solo due stati (iniziale e finale) tali per cui posso 
 raggiungere solo lo stato finale se ho un atomo accettato. Le stringhe
 che verranno riconosciute saranno formate da un solo elemento [a], [ab],
 [abc], .... se RE = oneof(a, ab, abc, ...).
 _______________________________________________________________________________
  
  Implementazione della nfa_recognize/2 { nfa_recognize(FA_Id, Input) }:
  FA_Id identifica l'automa che devo utilizzare per riconoscere la stringa,
  Input è una lita ed è la stringa che devo riconoscere.
  Effettuo dei controlli sull'input: FA_Id non puo' essere una varibile e
  neanche l'Input. Elimino dalla base di conoscenza tutti i fatti di questo NFA
  riguardanti il loop (clear_loop/1).
  loop/4 { loop(FA_Id, P, A, N) }:
  Questo predicato serve per effettuare una sorta di memoria anti-loop. 
  Il primo parametro è il solito FA_Id, il secondo e il terzo parametro
  indicano degli stati (P partenza e A arrivo), e N il numero di volte che ho 
  già effettuato la epsilon-mossa che li collega.
  Prendo  lo stato iniziale dell' NFA e utilizzando lo stesso predicato con
  tre parametri provo il riconoscimento.
  nfa_recognize/3 { nfa_recognize(FA_Id, Input, Q) } dove Q è il nuovo parametro
  ed indica lo stato iniziale.
  Ho quattro diversi casi:
  
  1° caso. 
  L'input che sto considerando è la lista vuota e mi trovo in un certo  
  stato Q. E' VERO se lo stato in cui mi trovo è uno stato finale per l'auoma
  identificato da FA_Id.
  
  2° caso.
  L'input che considero è diverso dalla lista vuota [I | Input] e mi trovo in
  un certo stato Q. Se nella mia base di conoscenza è presente una delta con
  quello stato Q che mi consente di spostarmi in P "consumando" I, ricorsiamente
  vado a verificare se riesco a riconoscere il resto della stringa partendo da P
  (stato generato dalla delta).
  
  3° caso: ('Input' unifica con qualunque lista compresa la vuota)
  Verifico se nella mia base di conoscenza è presente una transizione che mi
  permette di spostarmi da Q a P leggendo epsilon (ossia niente). Gestisco il
  caso di loop. Se non ho ancora effettuato questa epsilon-mossa la salvo,
  assegnando '1' al contatore dell'utilizzo. Verifico ricorsivamente da P.
  
  4° caso: 
  come prima considero le epsilon-mosse che mi fanno spostare da Q a P. 
  In questo caso è già presente nella mia base di conoscenza un fatto loop
  con questi due stati dunque, prendo il contatore (ultimo parametro N) e
  se non ho già effettuato un numero di volte abbastanza grande (100) questa
  transizione allora incremento N e reinserisco il fatto loop con N 
  icrementato nella base di conoscenza.
  
  Ho aggiunto il predicato loop/4 per gestire espressioni regolari del tipo
  star(star(a)) oppure star(plus(a)) e cosi via...
  
  Non inserisco i cut perchè utilizzando degli automi non deterministici potrei
  avere più percorsi possibili e necessariament devo controllarli tutti. Ne 
  inserisco solo uno nel 1° caso quando ormai ho raggiunto il successo.
  Il 3° e il 4° caso effettuano la funzione di Enclosure dello stato Q:
  Se dallo stato Q non è possibile spostarsi leggendo un carattere della stringa
  allora verifico se negli altri n stati (n>=0) raggiungibili con epsilon-mosse
  è possibile continuare il riconoscimento. Devo controllare tutti i percorsi.
  ______________________________________________________________________________
  
  Predicati du Utility:
  nfa_clear/1. Il parametro usato è FA_Id. Attraverso il predicato di 
  manipolazione retact_all/1, elimino dalla base di conoscenza tutti i fatti
  riguardanti l'automa identificato da FA_Id.
  nfa_clear/0. Come il suo omonimo con 1 parametro elimina dalla base di 
  conoscenza qualsiasi fatto riguarante gli automi (utilizza la nfa_clear/1 a
  cui passa la variabile anonima _).
  
  nfa_list/1. Il parametro che gli passo è FA_Id. Attraverso la listing 
  visualizzo tutti i fatti riguardanti l'automa identificato da FA_Id.
  nfa_list/0. Stessa cosa della nfa_lit/1 solo che lo fa per tutti i fatti 
  riguardanti qualsiaisi automa presente nella base di conoscenza (utilizza
  nfa_list/1 a cui passa  la variabile anonima _).