module CellMLToolkit

using MathML

using SymbolicUtils: FnType, Sym, operation, arguments
using ModelingToolkit
using EzXML

include("utils.jl")
export curl_exposures

# include("cellml.jl")
include("accessors.jl")
include("components.jl")

"""
    reads a CellML path or io and returns an ODEProblem
"""
function read_cellml(path, tspan)
    xml = readxml(path)
    ml = CellModel(xml, process_components(xml))
    ODEProblem(ml, tspan)
end

"""
    parses a CellML XML string and returns an ODEProblem
"""
function parse_cellml(xmlstr::AbstractString, tspan)
    xml = parsexml(xmlstr)
    ml = CellModel(xml, process_components(xml))
    ODEProblem(ml, tspan)
end

##############################################################################

export CellModel, ODEProblem
export read_cellml, parse_cellml
export list_params, list_states
export readxml, getxml, getsys
export update_list!

struct CellModel
    xml::EzXML.Document
    sys::ODESystem
end

getxml(ml::CellModel) = ml.xml
getsys(ml::CellModel) = ml.sys

"""
    constructs a CellModel struct for the CellML model defined in path
"""
function CellModel(path::AbstractString)
    xml = readxml(path)
    CellModel(xml, process_components(xml))
end

list_params(ml::CellModel) = find_sys_p(ml.xml, ml.sys)
list_states(ml::CellModel) = find_sys_u0(ml.xml, ml.sys)

import ModelingToolkit.ODEProblem

"""
    ODEProblem constructs an ODEProblem from a CellModel
"""
function ODEProblem(ml::CellModel, tspan;
        jac=false, level=1, p=last.(list_params(ml)), u0=last.(list_states(ml)))
    ODEProblem(ml.sys, u0, tspan, p; jac=jac)
end

function update_list!(l, sym, val)
    i = findfirst(isequal(sym), Symbol.(first.(l)))
    if i != nothing
        l[i] = (first(l[i]) => val)
    else
        @warn "symbol $sym not found"
    end
end

end # module
