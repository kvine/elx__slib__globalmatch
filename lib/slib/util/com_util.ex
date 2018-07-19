defmodule  Com.Util do

    import Convert.Util, only: :functions
    @doc """
     convert map key to atom
    """
    def convert_map_key_to_atom(map)  when is_map(map) do
        Map.new(map, fn {k,v} -> {string_to_atom(k),convert_map_key_to_atom(v)} end)
    end
    def convert_map_key_to_atom(map) when is_list(map) do 
        for i<- map do 
            convert_map_key_to_atom(i) 
        end
    end
    def convert_map_key_to_atom(map) do
         map
    end

    @doc """
        conver string to atom
    """
    def string_to_atom(string) when is_binary(string) do 
            String.to_atom(string)
    end

    def string_to_atom(string) do
            string
    end

    @doc """
        sparse list by span
        awlay keep the first and last elem
    """
    def sparse_list(list, span) when span > 0 do 
        length=length(list)
        case length <= span do 
                true -> 
                    list
                false -> 
                    first=Enum.at(list,0)
                    last=Enum.at(list,length-1)
                    list=Enum.drop_every(list,span)
                    case rem(length-1,span) == 0 do 
                        true -> 
                            ## last element is drop
                            Enum.concat([first|list],[last])
                        false ->
                            [first|list]
                    end
        end
    end

    def sparse_list(list,span) do 
        list
    end


    @doc """
        get tuple by str
        string : data1_data2_data3
        tuple must be integer
    """
    # -> {integer,integer,integer}
    def get_3_tuple_by_str(str) do 
        [d1,d2,d3]=:binary.split(str,<<"_">>,[:global])
        {
          b2i(d1),
          b2i(d2),
          b2i(d3)
        }
    end

     # -> [{integer,integer,integer}] | {:error,reason}
    def get_3_tuples_by_str(str) do 
         case str do 
              "" -> []
              _ -> 
               datas=:binary.split(str,<<"__">>,[:global])
               try do 
                    for data <- datas do 
                        get_3_tuple_by_str(data)
                    end
               rescue 
                 _ -> 
                    {:error,:bad_arg}
               end
         end
    end

    # -> [integer]
    def get_list_by_str(str) do 
            l=:binary.split(str,<<"_">>,[:global])
            for i<- l do 
                b2i(i)
            end
    end

    # -> %{type: type, id: id, num: num}
    def get_item(str) do 
            data=get_3_tuple_by_str(str)
            {type,id,num}=data
            %{type: type, id: id, num: num}
    end

    # -> [%{type: type, id: id, num: num}]
    def get_items(str) do 
            datas=get_3_tuples_by_str(str)
            for data <- datas do 
                {type,id,num}=data
                %{type: type, id: id, num: num}
            end
    end

     @doc """
        get tuple by str
        string : data1_data2_data3#data4
        tuple must be integer
    """
    # -> {integer,integer,integer,integer}
    def get_4_tuple_by_str(str) do 
        [d1,d2,d3]=:binary.split(str,<<"_">>,[:global])
        [d4,d5]=:binary.split(d3,<<"#">>,[:global])
        {
          b2i(d1),
          b2i(d2),
          b2i(d4),
          b2i(d5)
        }
    end

    # -> [{integer,integer,integer,integer}] | {:error,reason}
    def get_4_tuples_by_str(str) do 

         case str do 
              "" -> []
              _ -> 
               datas=:binary.split(str,<<"__">>,[:global])
               try do 
                    for data <- datas do 
                        get_4_tuple_by_str(data)
                    end
               rescue 
                 _ -> 
                    {:error,:bad_arg}
               end
         end
    end
    

    # -> %{type: type, id: id, num1: num1, num2: num2}
    def get_rd_item(str) do 
        data=get_4_tuple_by_str(str)
        {type,id,num1,num2}=data
        %{type: type, id: id, num1: num1, num2: num2}
    end

    # -> %{type: type, id: id, num: num}
    def get_item_by_rd(rd_item) do 
        num=Random.Util.rand_range(rd_item.num1,rd_item.num2)
        type =rd_item.type
        id= rd_item.id
        %{type: type, id: id, num: num}
    end

    # ->[%{type: type, id: id, num1: num1, num2: num2}]
    def get_rd_items(str) do 
          datas=get_4_tuples_by_str(str)
            for data <- datas do 
                {type,id,num1,num2}=data
                %{type: type, id: id, num1: num1,num2: num2}
            end
    end

    @doc """
     comb lists and delete repeat elements
    # Com.Util.comb_lists([[1,2,3],[2,3],[{1,3}]])
    """

    def comb_lists(lists) do 
        l=:lists.foldl(fn(x,acc)-> 
                            :lists.foldl(fn(x1,acc1)->
                                case :lists.member(x1,acc1) do 
                                    true -> acc1
                                    false -> [x1|acc1]
                                end
                            end,acc,x)
            end,[],lists)
         :lists.reverse(l)
    end

    @doc """
        clamp the x between min and max
    """
    def clamp(x,min,max) do 
        case {x< min, x> max} do 
            {true,false}-> min
            {false,true}-> max
            _ -> x
        end
    end

    def clamp_min(x,min) do 
        case x< min do 
            true -> min 
            false -> x
        end
    end

    def clamp_max(x,max) do 
        case x> max do 
            true -> max
            false -> x 
        end
    end

    @doc """
        add 
    """
    def add(value,add,is_add) do 
        case is_add do 
            true -> value+ add
            false -> value
        end
    end

    @doc """
        string to bool
    """
    def string_to_bool(string) do 
        case string do 
            "true" -> true
            "1" -> true
            "0"-> false
            _ -> false
        end
    end

    def test(id,_v) do 
        id
    end
    
end