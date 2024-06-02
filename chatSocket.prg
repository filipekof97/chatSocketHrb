
static aMensagens := {}
static aConexoes  := {}
static lPause     := .f.

#define PORTA                        2002
#define INTERVALO_THRED_EM_SEGUNDOS  2

/*******************************************************************************/
procedure main()

   local cNomeUsuario, nTipoConexao, cIPServidor, GetList := {}, cMensagem, pConexao, lErroEnvio

   cls

   Setmode(25,80)

   nTipoConexao := Alert( "Tipo de Conexao", { 'Servidor', 'Cliente' } )

   if Empty( nTipoConexao )
      return
   endif

   cNomeUsuario := Space( 15 )
   cIPServidor  := Space( 15 )

   @ 01,01 say 'Seu nome......: ' get cNomeUsuario picture "@!" valid !Empty( cNomeUsuario )

   if nTipoConexao == 2
      @ 02,01 say 'IP do Servidor: ' get cIPServidor valid !Empty( cNomeUsuario )
   endif

   read

   if LastKey() == 27
      return
   endif
   cls
   @ 01,01 to 20,79 DOUBLE
   @ 22,01 to 24,79

   cNomeUsuario := AllTrim( cNomeUsuario )

   HB_INetInit()

   HB_ThreadStart( @ControleConexoes(), nTipoConexao, cNomeUsuario, cIPServidor )

   do while .t.

      cMensagem := Space( 75 )
      @ 23, 02 say '>' get cMensagem valid !Empty( cMensagem )
      read

      if LastKey() == 27
         lPause := .t.
         if Alert( "Deseja sair?", { 'Sim', 'Nao' } ) == 1
            exit
         endif
         lPause := .f.
      endif

      if !Empty( cMensagem )
         lErroEnvio := EnviaMensagensTodasConexoes( cNomeUsuario + ': ' + cMensagem + hb_inetCRLF() )
         AAdd( aMensagens, cNomeUsuario + ': ' + Alltrim( cMensagem ) + IIF( lErroEnvio, '[Erro]', '' ) )
         EscreverConsoleMensagens()
      endif

   enddo

   cls

   for each pConexao in aConexoes
      HB_INetClose( pConexao )
   next

   HB_InetCleanup()


return

/*******************************************************************************/
static procedure ControleConexoes( nTipoConexao, cNomeUsuario, cIPServidor)

   local n, pConexao, cBuffer, nUltimaVez, pServidor

   if nTipoConexao == 1
      pServidor := HB_InetServer( PORTA )
      AAdd( aMensagens, cNomeUsuario + ': Inicializou o servidor' )
      HB_InetTimeout( pServidor, 500)
   else
      pConexao := HB_InetConnectIP( cIPServidor, PORTA )
      AAdd( aMensagens, cNomeUsuario + ': Conectou com o servidor' )
      HB_InetTimeout( pConexao, 500)
      AAdd( aConexoes, pConexao )
   endif

   nUltimaVez := Seconds()

   do while .t.

      IF nUltimaVez + INTERVALO_THRED_EM_SEGUNDOS > Seconds()
         loop
      ENDIF

      nUltimaVez := Seconds()

      if lPause
         loop
      endif

      if nTipoConexao == 1
         pConexao := HB_InetAccept( pServidor )

         if pConexao != nil
            AAdd( aMensagens, 'Entrou um novo usuario' )

            for n := 1 to Len( aConexoes )
               hb_inetSend( pConexao, 'Entrou um novo usuario' + hb_inetCRLF() )
            next

            AAdd( aConexoes, pConexao )

         endif
      endif

      if !Empty( aConexoes )
         for n := 1 to Len( aConexoes )
            if hb_inetDataReady( aConexoes[ n ], 100 ) > 0
               cBuffer := Space( 77 )
               hb_inetRecv( aConexoes[ n ], @cBuffer )

               if !Empty( cBuffer )
                  AAdd( aMensagens, Alltrim( cBuffer ) )

                  if nTipoConexao == 1
                     EnviaMensagensTodasConexoes( Alltrim( cBuffer ), n )
                  endif

               endif

            endif
         next
      endif

      EscreverConsoleMensagens()

   enddo


return

/*******************************************************************************/
procedure EscreverConsoleMensagens()

   local n, nLinha  := 2

   for n := Max( 1, Len( aMensagens ) - 17 ) to Len( aMensagens )
      @ nLinha++, 02 say PadR( aMensagens[ n ], 77 ) color 'G'
   next

return

/*******************************************************************************/
static function EnviaMensagensTodasConexoes( cMensagem, nConexaoNaoEnviar)

   local n, lHouveErro := .f.

   for n := 1 to Len( aConexoes )

      if !Empty( nConexaoNaoEnviar ) .and. nConexaoNaoEnviar == n
         loop
      endif

      lHouveErro := hb_inetSend( aConexoes[ n ], cMensagem ) <= 0 .or. lHouveErro

   next

return lHouveErro

